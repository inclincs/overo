#include "wavfile.h"

#include <stdlib.h>
#include <string.h>



void wavfile_free(struct wavfile* wav) {
    for (int c = 0; c < wav->channels; c++) {
        free(wav->signals[c]);
    }
    
    free(wav->signals);
    
    memset(wav, 0, sizeof(struct wavfile));
}
