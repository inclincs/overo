package com.example.overo.overo.audio;

import android.util.Log;

import com.example.overo.audio.codec.AACDecoder;
import com.example.overo.audio.codec.AACEncoder;
import com.example.overo.audio.io.WavAudio;
import com.example.overo.overo.audio.block.BlockGenerator;
import com.example.overo.overo.audio.block.Block;
import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;

import java.io.File;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class SpeakerProtectedAudio extends Audio {
    public SpeakerProtectedAudio(String name, double[] signals, long samplingRate, int bitPerSample, int channels) {
        super(name, signals, samplingRate, bitPerSample, channels);
    }

    public static SpeakerProtectedAudio load(File storage, String audioName) {
        File audioStorage = new File(storage, "audio");
        File tempStorage = new File(storage, "temp");

        String aacFilePath = new File(audioStorage, audioName + ".aac").getAbsolutePath();
        String wavFilePath = new File(tempStorage, audioName + ".wav").getAbsolutePath();

        AACDecoder decoder = new AACDecoder();
        decoder.AACDecode(aacFilePath, wavFilePath);

        WavAudio audio = new WavAudio();
        double[] signals = audio.read(wavFilePath);

        return new SpeakerProtectedAudio(
                audioName, signals, audio.getSampleRate(), audio.getBits(), audio.getNumChannels());
    }

    @Override
    public void store(File storage, String audioName) {
        File tempStorage = new File(storage, "temp");
        File audioStorage = new File(storage, "audio");

        String wavFilePath = new File(tempStorage, name + ".wav").getAbsolutePath();
        String aacFilePath = new File(audioStorage, name + ".aac").getAbsolutePath();

        WavAudio audio = new WavAudio();
        audio.write(wavFilePath, signals, (int) samplingRate, bitPerSample, channels);

        AACEncoder encoder = new AACEncoder();
        encoder.AACEncode(wavFilePath, aacFilePath);
        Log.e("speakerProtected", wavFilePath + ", " + aacFilePath);
    }

    @Override
    public AudioHash hash(int blockSize, VoiceTransformParameter parameter) throws NoSuchAlgorithmException {
        MessageDigest messageDigest = MessageDigest.getInstance("SHA1");

        BlockGenerator blockGenerator = new BlockGenerator(signals, blockSize);

        for (Block block : blockGenerator) {
            byte[] block_hash = block.hash(parameter);

            messageDigest.update(block_hash);
        }

        byte[] audio_hash = messageDigest.digest();

        return new AudioHash(audio_hash);
    }
}
