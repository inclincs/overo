package com.example.overo.overo.audio;

import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;

import java.io.File;
import java.security.NoSuchAlgorithmException;

public class SpeechProtectedAudio extends Audio {
    public SpeechProtectedAudio(String name, double[] signals, long samplingRate, int bitPerSample, int channels) {
        super(name, signals, samplingRate, bitPerSample, channels);
    }

    public static SpeechProtectedAudio load(File storage, String audioName) {
//        samples, samplingRate = FAAD.decode(filePath);

//        return new SpeechProtectedAudio(samples);
        return null;
    }

    @Override
    public void store(File storage, String file) {
//        FAAC.encode(filePath, samples);
    }

    @Override
    public AudioHash hash(int blockSize, VoiceTransformParameter parameter) throws NoSuchAlgorithmException {
        return null;
    }
}
