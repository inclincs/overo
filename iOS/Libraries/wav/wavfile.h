#ifndef __WAV_WAVFILE_H__
#define __WAV_WAVFILE_H__

struct wavfile {
    unsigned int subchunk1_size;
    unsigned short tag;
    unsigned short channels;
    unsigned int sampling_rate;
    unsigned int byte_rate;
    unsigned short block_alignment;
    unsigned short bit_per_sample;
    unsigned int subchunk2_size;
    double** signals;
    int signal_length;
};

void wavfile_free(struct wavfile*);

#endif
