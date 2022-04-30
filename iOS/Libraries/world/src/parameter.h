//-----------------------------------------------------------------------------
// Copyright 2012 Masanori Morise
// Author: mmorise [at] meiji.ac.jp (Masanori Morise)
// Last update: 2021/02/15
//-----------------------------------------------------------------------------
#ifndef WORLD_PARAMETER_H_
#define WORLD_PARAMETER_H_

//#include <jni.h>

#include "macrodefinitions.h"
#include "dio.h"
#include "cheaptrick.h"
#include "d4c.h"

WORLD_BEGIN_C_DECLS

typedef struct {
    double frame_period;
    int fs;

    double *f0;
    double *time_axis;
    int f0_length;

    double **spectrogram;
    double **aperiodicity;
    int fft_size;
} WorldParameters;

void SetParametersForF0Estimation(WorldParameters* world_parameters, DioOption* option, int fs);

void SetParametersForSpectrogramEstimation(WorldParameters* world_parameters,
                                           CheapTrickOption* option,
                                           double* f0,
                                           int f0_length,
                                           double* timeaxis,
                                           int fs);
void SetParametersForAperiodicityEstimation(WorldParameters* world_parameters, D4COption* option,
                                            double* f0, int f0_length, double* timeaxis, int fs);

WORLD_END_C_DECLS

#endif
