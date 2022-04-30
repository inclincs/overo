#include "encode.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>






static int compose(FILE* file, const struct wavfile* wav) {
    // Header
    fwrite("RIFF", sizeof(unsigned char), 4, file);
    
    unsigned int wave_code_size = 4;
    unsigned int format_header_size = 4 + 4;
    unsigned int format_size = 16;
    
    unsigned int data_header_size = 4 + 4;
    unsigned int data_size = wav->signal_length * wav->channels * wav->bit_per_sample / 8;
    
    unsigned int chunk_size = wave_code_size + format_header_size + format_size + data_header_size + data_size;
    fwrite(&chunk_size, sizeof(unsigned char), 4, file);
    
    fwrite("WAVE", sizeof(unsigned char), 4, file);
    
    fwrite("fmt ", sizeof(unsigned char), 4, file);
    fwrite(&format_size, sizeof(unsigned char), 4, file);
    
    fwrite(&wav->tag, sizeof(unsigned char), 2, file);
    fwrite(&wav->channels, sizeof(unsigned char), 2, file);
    
    fwrite(&wav->sampling_rate, sizeof(unsigned char), 4, file);
    fwrite(&wav->byte_rate, sizeof(unsigned char), 4, file);
    
    fwrite(&wav->block_alignment, sizeof(unsigned char), 2, file);
    fwrite(&wav->bit_per_sample, sizeof(unsigned char), 2, file);
    
    fwrite("data", sizeof(unsigned char), 4, file);
    fwrite(&data_size, sizeof(unsigned char), 4, file);
    
    
    // Data
    int byte_per_sample = wav->bit_per_sample / 8;
    
    int sample_in_channel;
    
    unsigned int scale = 1 << (wav->bit_per_sample - 1);
    
    for (int i = 0; i < wav->signal_length; i++) {
        for (int c = 0; c < wav->channels; c++) {
            sample_in_channel = wav->signals[c][i] * scale;
            
            if (byte_per_sample == 4) {
                int sample = sample_in_channel;
                fwrite(&sample, sizeof(unsigned char), 4, file);
            }
            else if (byte_per_sample == 2) {
                short sample = sample_in_channel;
                fwrite(&sample, sizeof(unsigned char), 2, file);
            }
            else if (byte_per_sample == 1) {
                unsigned char sample = sample_in_channel + 128;
                fwrite(&sample, sizeof(unsigned char), 1, file);
            }
        }
    }
    
    return 0;
}


void encode(const char* path, const struct wavfile* wav) {
    FILE* file = fopen(path, "wb");
    
    if (!file)
    {
        fprintf(stderr, "Error ... opening file: %s\n", path);
        return;
    }
    

    compose(file, wav);
    
    
    fclose(file);
}
