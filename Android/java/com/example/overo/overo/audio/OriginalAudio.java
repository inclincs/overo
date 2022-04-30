package com.example.overo.overo.audio;

import android.util.Log;

import com.example.overo.audio.codec.AACDecoder;
import com.example.overo.audio.io.WavAudio;
import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;

import java.io.File;
import java.security.NoSuchAlgorithmException;

public class OriginalAudio extends Audio {
    public OriginalAudio(String name, double[] samples, long samplingRate, int bitPerSample, int channels) {
        super(name, samples, samplingRate, bitPerSample, channels);
    }

    public static OriginalAudio load(File storage, String audioName) {
        File audioStorage = new File(storage, "audio");
        File tempStorage = new File(storage, "temp");

        if (new File(audioStorage, audioName + "_origin.aac").exists()) {
            Log.e("aac exist", "true");
        }
        else {
            Log.e("aac exist", "false");
        }
        String inputFilePath = new File(audioStorage, audioName + "_origin.aac").getAbsolutePath();
        String outputFilePath = new File(tempStorage, audioName + "_origin.wav").getAbsolutePath();

        AACDecoder aacDecoder = new AACDecoder();
        aacDecoder.AACDecode(inputFilePath, outputFilePath);

        Log.e("aacDecoder", inputFilePath);
        Log.e("aacDecoder", outputFilePath);

        WavAudio audio = new WavAudio();
        double[] signals = audio.read(outputFilePath);

        OriginalAudio originalAudio = new OriginalAudio(
                audioName, signals, audio.getSampleRate(), audio.getBits(), audio.getNumChannels());

        return originalAudio;
    }

    @Override
    public void store(File storage, String file) {}

    @Override
    public AudioHash hash(int blockSize, VoiceTransformParameter parameter) throws NoSuchAlgorithmException {
        return null;
    }
}
