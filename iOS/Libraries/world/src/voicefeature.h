#ifndef __VOICE_FEATURE_H__
#define __VOICE_FEATURE_H__

struct voicefeature {
    double* f0;
    double* temporal_positions;
    double** spectrogram;
    double** aperiodicity;
    int f0_length;
    int spectral_length;
};

#endif
