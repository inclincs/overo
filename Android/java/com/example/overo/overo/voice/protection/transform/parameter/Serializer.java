package com.example.overo.overo.voice.protection.transform.parameter;

import com.example.overo.utility.Binarization;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

public class Serializer {
    public static void store(File storage, String file, VoiceTransformParameter parameter) throws IOException {
        // file format: pitch | spectra
        FileOutputStream fileOutputStream = new FileOutputStream(new File(storage, file), false);
        BufferedOutputStream bufferedOutputStream = new BufferedOutputStream(fileOutputStream);

        writePitch(bufferedOutputStream, parameter.pitch);
        writeSpectra(bufferedOutputStream, parameter.spectra);

        bufferedOutputStream.close();
    }

    protected static void writePitch(BufferedOutputStream bufferedOutputStream, VoiceTransformParameter.Pitch pitch) throws IOException {
        // pitch := mean(64) | std(64)
        byte[] pitchMean = Binarization.binarize(pitch.mean);
        byte[] pitchStd = Binarization.binarize(pitch.std);

        bufferedOutputStream.write(pitchMean);
        bufferedOutputStream.write(pitchStd);
    }

    protected static void writeSpectra(BufferedOutputStream bufferedOutputStream, VoiceTransformParameter.Spectrum[] spectra) throws IOException {
        // spectra := spectrum[0] | spectrum[1] | ...
        // spectrum := sample indices | warping slopes
        for (VoiceTransformParameter.Spectrum spectrum : spectra) {
            // sample indices := start(64) | end(64)
            byte[] startIndex = Binarization.binarize(spectrum.startSampleIndex);
            byte[] endIndex = Binarization.binarize(spectrum.endSampleIndex);

            bufferedOutputStream.write(startIndex);
            bufferedOutputStream.write(endIndex);

            // warping slopes := alpha(64) | beta(64)
            byte[] alpha = Binarization.binarize(spectrum.warpingSlopes[0]);
            byte[] beta = Binarization.binarize(spectrum.warpingSlopes[1]);

            bufferedOutputStream.write(alpha);
            bufferedOutputStream.write(beta);
        }
    }
}
