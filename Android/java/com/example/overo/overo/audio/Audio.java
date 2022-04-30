package com.example.overo.overo.audio;

import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;

import java.io.File;
import java.security.NoSuchAlgorithmException;

public abstract class Audio {

    public final String name;
    public double[] signals;
    public long samplingRate;
    public int bitPerSample;
    public int channels;

    public Audio(String name, double[] signals, long samplingRate, int bitPerSample, int channels) {
        this.name = name;
        this.signals = signals;
        this.samplingRate = samplingRate;
        this.bitPerSample = bitPerSample;
        this.channels = channels;
    }

    public abstract void store(File storage, String file);

    public abstract AudioHash hash(int blockSize, VoiceTransformParameter parameter) throws NoSuchAlgorithmException;

    public void dispose() {
        signals = null;
    }
}
