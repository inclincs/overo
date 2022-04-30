package com.example.overo.overo.voice.protection.transform.parameter;

import com.example.overo.utility.Binarization;
import com.example.overo.utility.Hash;

import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.security.NoSuchAlgorithmException;
import java.util.Locale;

public class VoiceTransformParameter {

    public static class Pitch {
        public double mean;
        public double std;
    }

    public static class Spectrum {
        public long startSampleIndex;
        public long endSampleIndex;
        public double[] warpingSlopes;
        public byte[] hashedWarpingSlopes;
    }

    public Pitch pitch;
    public Spectrum[] spectra;

    boolean isHashed;

    public VoiceTransformParameter(Pitch pitch, Spectrum[] spectra) {
        this.pitch = pitch;
        this.spectra = spectra;

        isHashed = false;
    }

    public void store(File storage, String file) {
        try {
            FileWriter fileWriter = new FileWriter(new File(storage, file), false);
            BufferedWriter bufferedWriter = new BufferedWriter(fileWriter);

            bufferedWriter.append(String.format(Locale.KOREA, "%f %f", pitch.mean, pitch.std));
            bufferedWriter.newLine();

            for (int i = 0; i < spectra.length; i++) {
                Spectrum spectrum = spectra[i];

                String indices = String.format(
                        Locale.KOREA,
                        "%d %d",
                        spectrum.startSampleIndex, spectrum.endSampleIndex
                );

                bufferedWriter.append(indices);
                bufferedWriter.newLine();

                String warpingSlopes = String.format(
                        Locale.KOREA,
                        "%f %f",
                        spectrum.warpingSlopes[0], spectrum.warpingSlopes[1]
                );

                bufferedWriter.append(warpingSlopes);
                bufferedWriter.newLine();

                if (i < spectra.length - 1) {
                    bufferedWriter.newLine();
                }
            }

            bufferedWriter.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static VoiceTransformParameter load(File storage, String file) {
        return null;
    }

    public boolean isHashed() {
        return isHashed;
    }

    public void hash() throws NoSuchAlgorithmException {
        for (Spectrum spectrum : spectra) {
            byte[] binarizedWarpingSlope = Binarization.binarize(spectrum.warpingSlopes);

            spectrum.hashedWarpingSlopes = Hash.hash("SHA1", binarizedWarpingSlope);
        }

        isHashed = true;
    }

    public void dispose() {
        pitch = null;

        for (Spectrum spectrum : spectra) {
            spectrum.warpingSlopes = null;
            spectrum.hashedWarpingSlopes = null;
        }
        spectra = null;
    }

    public static VoiceTransformParameter fromWorld(Object result) {
//        Pitch pitch = new Pitch();
//        pitch.mean = result.vtp.pitch.mean;
//        pitch.std = result.vtp.pitch.std;
//
//        Spectrum[] spectra = new Spectrum[result.vtp.spectrum.length];
//
//        for (int i = 0; i < result.vtp.spectrum.length; i++) {
//            Spectrum spectrum = new Spectrum();
//            spectrum.startSampleIndex = result.vtp.spectrum.startSampleIndex;
//            spectrum.endSampleIndex = result.vtp.spectrum.startSampleIndex; // last endSampleIndex is -1
//            spectrum.warpingSlopes = result.vtp.spectrum.warpingSlopes;
//
//            spectra[i] = spectrum;
//        }
//
//        return new VoiceTransformParameter(pitch, spectra);
        return null;
    }
}
