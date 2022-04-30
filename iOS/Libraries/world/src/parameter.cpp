#include "parameter.h"

#include <math.h>

#include "common.h"
#include "constantnumbers.h"
#include "matlabfunctions.h"

namespace {
    extern "C" {
        void SetParametersForF0Estimation(WorldParameters* world_parameters, DioOption* option, int fs){
            world_parameters->fs = fs;
            world_parameters->frame_period = 5.0;

            InitializeDioOption(option);

            option->frame_period = world_parameters->frame_period;
            option->speed = 1;
            option->f0_floor = 71.0;
            option->allowed_range = 0.1;
        }

        void SetParametersForSpectrogramEstimation(WorldParameters* world_parameters, CheapTrickOption* option,
                                                   double* f0, int f0_length, double* timeaxis, int fs){
            world_parameters->fs = fs;
            world_parameters->frame_period = 5.0;

            world_parameters->f0 = f0;
            world_parameters->f0_length = f0_length;
            world_parameters->time_axis = timeaxis;

            InitializeCheapTrickOption(world_parameters->fs, option);

            option->q1 = -0.15;
            option->f0_floor = 71.0;

            // Parameters setting and memory allocation.
            world_parameters->fft_size =
                    GetFFTSizeForCheapTrick(world_parameters->fs, option);
            world_parameters->spectrogram = new double *[world_parameters->f0_length];
            for (int i = 0; i < world_parameters->f0_length; ++i) {
                world_parameters->spectrogram[i] =
                        new double[world_parameters->fft_size / 2 + 1];
            }
        }

        void SetParametersForAperiodicityEstimation(WorldParameters* world_parameters, D4COption* option,
                                                    double* f0, int f0_length, double* timeaxis, int fs){
            world_parameters->fs = fs;
            world_parameters->frame_period = 5.0;

            world_parameters->f0 = f0;
            world_parameters->f0_length = f0_length;
            world_parameters->time_axis = timeaxis;

            CheapTrickOption c_option;
            InitializeCheapTrickOption(world_parameters->fs, &c_option);

            c_option.q1 = -0.15;
            c_option.f0_floor = 71.0;

            world_parameters->fft_size =
                    GetFFTSizeForCheapTrick(world_parameters->fs, &c_option);

            InitializeD4COption(option);

            world_parameters->aperiodicity = new double *[world_parameters->f0_length];
            for (int i = 0; i < world_parameters->f0_length; ++i) {
                world_parameters->aperiodicity[i] =
                        new double[world_parameters->fft_size / 2 + 1];
            }
        }
    }
}
