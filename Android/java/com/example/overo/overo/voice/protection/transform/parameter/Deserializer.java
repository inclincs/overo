package com.example.overo.overo.voice.protection.transform.parameter;

import com.example.overo.utility.Binarization;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.ArrayList;

public class Deserializer {
    public static VoiceTransformParameter load(File storage, String file) throws IOException {
        FileInputStream fileInputStream = new FileInputStream(new File(storage, file));
        BufferedInputStream bufferedInputStream = new BufferedInputStream(fileInputStream);

        VoiceTransformParameter.Pitch pitch = readPitch(bufferedInputStream);
        VoiceTransformParameter.Spectrum[] spectra = readSpectra(bufferedInputStream);

        bufferedInputStream.close();

        return new VoiceTransformParameter(pitch, spectra);
    }

    protected static VoiceTransformParameter.Pitch readPitch(BufferedInputStream bufferedInputStream) throws IOException {
        // pitch: mean(64) | std(64)
        VoiceTransformParameter.Pitch pitch = new VoiceTransformParameter.Pitch();

        byte[] mean = new byte[8];
        byte[] std = new byte[8];

        if (bufferedInputStream.read(mean) != mean.length) {
            return null;
        }
        if (bufferedInputStream.read(std) != std.length) {
            return null;
        }

        pitch.mean = Binarization.toDouble(mean)[0];
        pitch.std = Binarization.toDouble(std)[0];

        return pitch;
    }

    protected static VoiceTransformParameter.Spectrum[] readSpectra(BufferedInputStream bufferedInputStream) throws IOException {
        // spectra := spectrum[0] | ...
        ArrayList<VoiceTransformParameter.Spectrum> spectra = new ArrayList<>();

        while (true) {
            // spectrum := indices | warping slopes
            VoiceTransformParameter.Spectrum spectrum = new VoiceTransformParameter.Spectrum();

            // indices := start index(64) | end index(64)
            byte[] startIndex = new byte[8];
            byte[] endIndex = new byte[8];

            if (bufferedInputStream.read(startIndex) != startIndex.length) {
                break;
            }
            if (bufferedInputStream.read(endIndex) != endIndex.length) {
                break;
            }

            spectrum.startSampleIndex = Binarization.toLong(startIndex)[0];
            spectrum.endSampleIndex = Binarization.toLong(endIndex)[0];

            // warping slopes := alpha(64) | beta(64)
            byte[] alpha = new byte[8];
            byte[] beta = new byte[8];

            if (bufferedInputStream.read(alpha) != alpha.length) {
                break;
            }
            if (bufferedInputStream.read(beta) != beta.length) {
                break;
            }

            spectrum.warpingSlopes[0] = Binarization.toDouble(alpha)[0];
            spectrum.warpingSlopes[1] = Binarization.toDouble(beta)[0];

            spectra.add(spectrum);
        }

        return spectra.toArray(new VoiceTransformParameter.Spectrum[0]);
    }
}
