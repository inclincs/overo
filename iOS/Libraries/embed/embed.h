#ifndef __EMBED_H__
#define __EMBED_H__

void embed_hash(double* wave, const int wave_length, const unsigned char* hash, const int hash_bit_length);
void extract_hash(const double* wave, const int wave_length, unsigned char* hash, const int hash_bit_length);

#endif
