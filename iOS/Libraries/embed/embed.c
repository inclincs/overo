#include "embed.h"

#include <stdio.h>
#include <math.h>

#define EMBEDDING_BIT 8 // 11까지 괜찮음
#define BIT_PER_SAMPLE 16
#define DELAYED 0



void embed_hash(double* wave, const int wave_length, const unsigned char* hash, const int hash_bit_length) {
    int embedding_bit = EMBEDDING_BIT; // 1 ~ 64
    if (embedding_bit > sizeof(double) * 8) {
        return;
    }
    
    int required_sample_count = ceilf((float)hash_bit_length / embedding_bit); // 4 ~ 256
    
    if (required_sample_count > wave_length) {
        return;
    }
    
    unsigned char* d = 0;
    unsigned char h = 0, b = 0;
    
    for (int i = 0, hi = 0; i < required_sample_count; i++) {
        int sample = wave[i+DELAYED] * (1 << (BIT_PER_SAMPLE - 1));
//        printf("%08x ", sample);
//        printf("%d ", sample);
//        printf("%04x ", (hash[i*2+1] << 8) + hash[i*2]);
        
        d = (unsigned char *) (&sample);
        
        for (int j = 0; j < embedding_bit; j++, hi++) {
            int di = j / 8;
            int dj = j % 8;
            
            b = 1 << dj;
            
            d[di] &= ~b;
            
            h = (hash[hi / 8] >> (hi % 8)) & 1;
            
            if (h) {
                d[di] |= b;
            }
        }
        
//        printf("%08x\n", sample);
//        printf("%d\n", sample);
        
        wave[i+DELAYED] = (double)sample / (1 << (BIT_PER_SAMPLE - 1));
    }
}

void extract_hash(const double* wave, const int wave_length, unsigned char* hash, const int hash_bit_length) {
    int embedding_bit = EMBEDDING_BIT; // 1 ~ 64
    if (embedding_bit > sizeof(double) * 8) {
        return;
    }
    
    int required_sample_count = ceilf((float)hash_bit_length / embedding_bit); // 4 ~ 256
    
    if (required_sample_count > wave_length) {
        return;
    }
    
    unsigned char* d = 0;
    unsigned char h = 0;
    
    for (int i = 0, hi = 0; i < required_sample_count; i++) {
        int sample = wave[i+DELAYED] * (1 << (BIT_PER_SAMPLE - 1));
//        printf("%08x ", sample);
        d = (unsigned char *) (&sample);
//        d = (unsigned char *) (wave + i);
        
        for (int j = 0; j < embedding_bit; j++, hi++) {
            int di = j / 8;
            int dj = j % 8;
            
            h = (d[di] >> dj) & 1;
            
            if (h) {
                hash[hi / 8] |= 1 << (hi % 8);
            }
        }
    }
}
