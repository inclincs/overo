#include "decode.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define BUFFER_SIZE 1024

#define valid_init(buf, size) _valid_init(buf, size)
#define _valid_init(buf, size) \
unsigned char* buf; \
unsigned long buf##_read_count; \
int err; \
buf = (unsigned char *) malloc(sizeof(unsigned char) * size); \
if (buf == NULL) { \
    return 1; \
} \
for (int i = 0; i < size; i++) { \
    buffer[i] = '\0'; \
}

#define valid_read(buf, len, file, err_msg) _valid_read(buf, len, file, err_msg)
#define _valid_read(buf, len, file, err_msg) \
buf##_read_count = fread(buf, sizeof(char), len, file); \
if (buf##_read_count != len) { \
    printf(err_msg); \
    err = 2; \
    goto error; \
}

#define valid_check(buf, target, len, err_code, err_msg) \
if (memcmp(buf, target, len)) { \
    printf(err_msg); \
    err = err_code; \
    goto error; \
}

#define valid_dispose(buf) free(buf);
#define valid_error() return err;


#define to_uint8(bytes) (unsigned char)((bytes)[0])
#define to_int16(bytes) (short)((bytes)[0] | (bytes)[1] << 8)
#define to_int32(bytes) ((bytes)[0] | (bytes)[1] << 8 | (bytes)[2] << 16 | (bytes)[3] << 24)


#define WAV_TAG_PCM 1
#define WAV_TAG_A_LAW 6
#define WAV_TAG_MU_LAW 7



static int parse(FILE* file, struct wavfile* wav) {
    valid_init(buffer, BUFFER_SIZE)
    
    
    // Chunk ID
    valid_read(buffer, 4, file, "Error ... chunk id\n")
    valid_check(buffer, "RIFF", 4, 3, "Error ... matching chunk id\n")
    
    // Chunk Size
    valid_read(buffer, 4, file, "Error ... chunk size\n")
    
    // Format
    valid_read(buffer, 4, file, "Error ... format\n")
    valid_check(buffer, "WAVE", 4, 4, "Error ... matching format\n")
    
    
    // Subchunk1 ID
    valid_read(buffer, 4, file, "Error ... subchunk1 id\n")
    valid_check(buffer, "fmt ", 4, 5, "Error ... matching subchunk1 id\n")

    // Subchunk1 Size
    valid_read(buffer, 4, file, "Error ... subchunk1 size\n")
    wav->subchunk1_size = to_int32(buffer);
    
    
    // Tag
    valid_read(buffer, 2, file, "Error ... tag\n")
    wav->tag = to_int16(buffer);
    
    if (wav->tag != WAV_TAG_PCM) {
        fprintf(stderr, "Error ... tag must be PCM: %d\n", wav->tag);
        return 6;
    }
    
    
    // number of Channels
    valid_read(buffer, 2, file, "Error ... channels\n")
    wav->channels = to_int16(buffer);
    
    // Sampling rate
    valid_read(buffer, 4, file, "Error ... sampling rate\n")
    wav->sampling_rate = to_int32(buffer);
    
    // Byte rate
    valid_read(buffer, 4, file, "Error ... byte rate\n")
    wav->byte_rate = to_int32(buffer);
    
    // Block alignment
    valid_read(buffer, 2, file, "Error ... block alignment\n")
    wav->block_alignment = to_int16(buffer);
    
    // Bit per sample
    valid_read(buffer, 2, file, "Error ... bit per sample\n")
    wav->bit_per_sample = to_int16(buffer);
    
    
    // Subchunk2 ID
    valid_read(buffer, 4, file, "Error ... subchunk2 id\n")
    valid_check(buffer, "data", 4, 4, "Error ... matching subchunk2 id\n")
    
    // Subchunk2 Size
    valid_read(buffer, 4, file, "Error ... subchunk2 size\n")
    wav->subchunk2_size = to_int32(buffer);
    
    
    // Data
    int byte_per_sample = wav->bit_per_sample / 8;
    wav->signal_length = wav->subchunk2_size / byte_per_sample / wav->channels;
    
    wav->signals = (double **) malloc(sizeof(double *) * wav->channels);
    
    if (wav->signals == NULL) {
        fprintf(stderr, "Error ... allocating signals\n");
        err = 1;
        goto error;
    }
    for (int c = 0; c < wav->channels; c++) {
        wav->signals[c] = (double *) malloc(sizeof(double) * wav->signal_length);
        if (wav->signals == NULL) {
            free(wav->signals);
            for (int r = c-1; r >= 0; r--) {
                free(wav->signals[r]);
            }
            fprintf(stderr, "Error ... allocating channel in signals\n");
            err = 1;
            goto error;
        }
    }
    
    
    int sample_in_channel;
    
    for (int i = 0; i < wav->signal_length; i++) {
        for (int c = 0; c < wav->channels; c++) {
            sample_in_channel = 0;

            if (byte_per_sample == 4) {
                valid_read(buffer, 4, file, "Error ... sample 4bytes\n")
                sample_in_channel |= buffer[0];
                sample_in_channel |= buffer[1] << 8;
                sample_in_channel |= buffer[2] << 16;
                sample_in_channel |= buffer[3] << 24;
            }
            else if (byte_per_sample == 2) {
                valid_read(buffer, 2, file, "Error ... sample 2bytes\n")
                sample_in_channel = (short)(buffer[0] | ((buffer[1] << 8)));
            }
            else if (byte_per_sample == 1) {
                valid_read(buffer, 1, file, "Error ... sample 1byte\n")
                sample_in_channel = buffer[0];
                sample_in_channel -= 128;
            }
            
            wav->signals[c][i] = (double)sample_in_channel / (1 << (wav->bit_per_sample - 1));
        }
    }
    
    
    valid_dispose(buffer);
    
    return 0;
    
error:
    valid_error()
}

void decode(const char* path, struct wavfile* wav) {
    FILE* file = fopen(path, "rb");
    
    if (!file)
    {
        fprintf(stderr, "Error ... opening file: %s\n", path);
        return;
    }
    
    
    memset(wav, 0, sizeof(struct wavfile));
    
    parse(file, wav);
    
    
    fclose(file);
}
