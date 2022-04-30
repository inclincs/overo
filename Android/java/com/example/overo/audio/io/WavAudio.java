package com.example.overo.audio.io;

import android.util.Log;

import java.io.File;

public class WavAudio {

    WavFile wavFile;
    double[] signal;

    public double[] read(String audio_file_path) {
        try
        {
            Log.e("audio file path", audio_file_path);
            wavFile = WavFile.openWavFile(new File(audio_file_path));

            long numFrames = wavFile.getNumFrames();
            int numChannels = wavFile.getNumChannels();

            int numSamples = (int) numFrames * numChannels;
            signal = new double[numSamples];

            int framesRead = 0;
            do
            {
                framesRead = wavFile.readFrames(signal, numSamples);
            }
            while (framesRead != 0);

            wavFile.close();
        }
        catch (Exception e)
        {
            System.err.println(e);
            e.printStackTrace();
        }

        return signal;
    }

    public void write(String audio_file_path, double[] x, int fs, int n_bits, int numChannels) {
        try
        {
            int numSamples = x.length;

            WavFile wavFile = WavFile.newWavFile(new File(audio_file_path), numChannels, numSamples, n_bits, fs);

            wavFile.writeFrames(x, numSamples);

            wavFile.close();
        }
        catch (Exception e)
        {
            System.err.println(e);
            e.printStackTrace();
        }
    }

    public long getSampleRate() {
        return wavFile.getSampleRate();
    }

    public int getNumChannels() {
        return wavFile.getNumChannels();
    }

    public int getBits() {
        return wavFile.getValidBits();
    }
}
