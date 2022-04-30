//-----------------------------------------------------------------------------
// Copyright 2012 Masanori Morise
// Author: mmorise [at] meiji.ac.jp (Masanori Morise)
// Last update: 2021/02/15
//-----------------------------------------------------------------------------
#ifndef WORLD_ANALYSIS_H_
#define WORLD_ANALYSIS_H_

#include "voicefeature.h"

#include "macrodefinitions.h"

WORLD_BEGIN_C_DECLS

void analyze(const double* x, const int x_length, const int sampling_rate, struct voicefeature* voice_feature);
//double** stonemask(const double *x, const int x_length, const int fs, int* f0_length);
//double** cheaptrick(const double* x, const int x_length, const int fs, const double* time_axis, const double* f0, const int f0_length, int* fft_size);
//double** d4c(const double* x, const int x_length, const int fs, const double* time_axis, const double* f0, const int f0_length);
//int getSuitableFFTSize(int sampling_rate);

WORLD_END_C_DECLS

#endif  // WORLD_ANALYSIS_H_
