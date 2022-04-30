//-----------------------------------------------------------------------------
// Copyright 2016 seblemaguer
// Author: https://github.com/seblemaguer
// Last update: 2017/02/01
//
// Summary:
// The example analyzes a .wav file and outputs three files in each parameter.
// Files are used to synthesize speech by "synthesis.cpp".
//
// How to use:
// The format is shown in the line 253.
//-----------------------------------------------------------------------------
#include "analysis.h"

#include <math.h>

// WORLD core functions.
// Note: win.sln uses an option in Additional Include Directories.
// To compile the program, the option "-I $(SolutionDir)..\src" was set.

#include "parameter.h"

#include "d4c.h"
#include "dio.h"
#include "matlabfunctions.h"
#include "cheaptrick.h"
#include "stonemask.h"


namespace {

WORLD_BEGIN_C_DECLS

void analyze(const double* x, const int x_length, const int sampling_rate, struct voicefeature* voice_feature) {
    DioOption dioOption = {0};
    InitializeDioOption(&dioOption);

    dioOption.frame_period = 5.0;
    dioOption.speed = 1;
    dioOption.f0_floor = 71.0;
    dioOption.allowed_range = 0.1;
    
    

    int f0_length = GetSamplesForDIO(sampling_rate, x_length, dioOption.frame_period);
    
    double* temporal_positions = new double[f0_length];
    double* f0 = new double[f0_length];
    
    Dio(x, x_length, sampling_rate, &dioOption, temporal_positions, f0);

    
    
    double *refined_f0 = new double[f0_length];
    
    StoneMask(x, x_length, sampling_rate, temporal_positions, f0, f0_length, refined_f0);

    for (int i = 0; i < f0_length; ++i) {
        f0[i] = refined_f0[i];
    }

    delete[] refined_f0;
    
    
    
    CheapTrickOption cheapTrickOption = {0};
    InitializeCheapTrickOption(sampling_rate, &cheapTrickOption);
    
    double** spectrogram = new double*[f0_length];
    
    for (int i = 0; i < f0_length; i++) {
        spectrogram[i] = new double[cheapTrickOption.fft_size / 2 + 1];
    }
    
    CheapTrick(x, x_length, sampling_rate, temporal_positions, f0, f0_length, &cheapTrickOption, spectrogram);
    
    
    
    D4COption d4cOption = {0};
    InitializeD4COption(&d4cOption);

    double** aperiodicity = new double*[f0_length];
    
    for (int i = 0; i < f0_length; i++) {
        aperiodicity[i] = new double[cheapTrickOption.fft_size / 2 + 1];
    }

    D4C(x, x_length, sampling_rate, temporal_positions, f0, f0_length, cheapTrickOption.fft_size, &d4cOption, aperiodicity);
    
    
    
    int spectral_length = cheapTrickOption.fft_size / 2 + 1;
    
    voice_feature->f0 = new double[f0_length];
    voice_feature->temporal_positions = new double[f0_length];
    voice_feature->spectrogram = new double*[f0_length];
    voice_feature->aperiodicity = new double*[f0_length];
    
    for (int i = 0; i < f0_length; i++) {
        voice_feature->f0[i] = f0[i];
        voice_feature->temporal_positions[i] = temporal_positions[i];
        
        voice_feature->spectrogram[i] = new double[spectral_length];
        voice_feature->aperiodicity[i] = new double[spectral_length];
        
        for (int j = 0; j < spectral_length; j++) {
            voice_feature->spectrogram[i][j] = spectrogram[i][j];
            voice_feature->aperiodicity[i][j] = aperiodicity[i][j];
        }
    }
    
    voice_feature->f0_length = f0_length;
    voice_feature->spectral_length = spectral_length;
}

//double** stonemask(const double *x, const int x_length, const int fs, int* f0_length) {
//    WorldParameters world_parameters;
//    DioOption option = {0};
//
//    SetParametersForF0Estimation(&world_parameters, &option, (int)fs);
//
//    world_parameters.f0_length = GetSamplesForDIO(world_parameters.fs,
//                                                  x_length, world_parameters.frame_period);
//    *f0_length = world_parameters.f0_length;
//    world_parameters.f0 = new double[world_parameters.f0_length];
//    world_parameters.time_axis = new double[world_parameters.f0_length];
//    double *refined_f0 = new double[world_parameters.f0_length];
//
//    Dio(x, x_length, world_parameters.fs, &option, world_parameters.time_axis,
//        world_parameters.f0);
//
//    StoneMask(x, x_length, world_parameters.fs, world_parameters.time_axis,
//              world_parameters.f0, world_parameters.f0_length, refined_f0);
//
//    for (int i = 0; i < world_parameters.f0_length; ++i)
//        world_parameters.f0[i] = refined_f0[i];
//
//    delete[] refined_f0;
//
//    int F0 = 0; int TimeAxis = 1;
//
//    double** F0_TimeAxis = (double**) malloc ( sizeof(double*) * 2 );
//    F0_TimeAxis[F0] = (double*) malloc ( sizeof(double) * world_parameters.f0_length );
//    F0_TimeAxis[TimeAxis] = (double*) malloc ( sizeof(double) * world_parameters.f0_length );
//
//    for (int i = 0; i < world_parameters.f0_length; i++){
//        F0_TimeAxis[F0][i] = world_parameters.f0[i];
//        F0_TimeAxis[TimeAxis][i] = world_parameters.time_axis[i];
//    }
//    
//    return F0_TimeAxis;
//}
//
//double** cheaptrick(const double* x, const int x_length, const int fs, const double* time_axis, const double* f0, const int f0_length, int* fft_size) {
//    CheapTrickOption option;
//
//    InitializeCheapTrickOption(fs, &option);
//    
//    double** spectrogram = new double*[f0_length];
//    
//    for (int i = 0; i < f0_length; i++)
//        spectrogram[i] = new double[option.fft_size / 2 + 1];
//    
//    
//    CheapTrick(x, x_length, fs, time_axis, f0, f0_length, &option, spectrogram);
//    
//    *fft_size = option.fft_size;
//    
//    return spectrogram;
//}
//
//double** d4c(const double* x, const int x_length, const int fs, const double* time_axis, const double* f0, const int f0_length) {
//    D4COption d4cOption;
//    CheapTrickOption cheapTrickOption;
//    
//    InitializeD4COption(&d4cOption);
//    InitializeCheapTrickOption(fs, &cheapTrickOption);
//
//    int fft_size = cheapTrickOption.fft_size;
//    double** aperiodicity = new double*[f0_length];
//    
//    for (int i = 0; i < f0_length; i++)
//        aperiodicity[i] = new double[fft_size / 2 + 1];
//
//    D4C(x, x_length, fs, time_axis, f0, f0_length, fft_size, &d4cOption, aperiodicity);
//    
//    return aperiodicity;
//}
//
//int getSuitableFFTSize(int sampling_rate) {
//    CheapTrickOption option;
//    
//    option.f0_floor = 71.0;
//
//    return GetFFTSizeForCheapTrick(sampling_rate, &option);
//}

WORLD_END_C_DECLS

} //namespace

/* analysis_prog.cpp ends here */
