package com.example.overo.overo.audio.block;

import com.example.overo.utility.Binarization;
import com.example.overo.utility.Hash;
import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;

public class Block {

    int index;
    double[] samples;

    public Block(int index, double[] samples) {
        this.index = index;
        this.samples = samples;
    }

    public byte[] hash(VoiceTransformParameter parameter) throws NoSuchAlgorithmException {
        byte[] blockSampleHash = hashBlockSamples();
        byte[] parameterHash = hashVoiceTransformParameterCollectively(parameter);

        return hashBlockWithParameters(blockSampleHash, parameterHash);
    }

    protected byte[] hashBlockSamples() throws NoSuchAlgorithmException {
        return Hash.hash("SHA1", Binarization.binarize(samples));
    }

    protected byte[] hashVoiceTransformParameterCollectively(VoiceTransformParameter parameter) throws NoSuchAlgorithmException {
        if (!parameter.isHashed()) {
            parameter.hash();
        }

        MessageDigest messageDigest = MessageDigest.getInstance("SHA1");

        ArrayList<byte[]> hashes = findVoiceTransformParameterHashes(parameter);

        for (byte[] hash : hashes) {
            messageDigest.update(hash);
        }

        return messageDigest.digest();
    }

    protected ArrayList<byte[]> findVoiceTransformParameterHashes(VoiceTransformParameter parameter) {
        ArrayList<byte[]> voiceTransformParameterHashes = new ArrayList<>();

        long blockStartSampleIndex = index * samples.length;
        long blockEndSampleIndex = blockStartSampleIndex + samples.length;

        for (int i = 0; i < parameter.spectra.length; i++) {
            VoiceTransformParameter.Spectrum spectrum = parameter.spectra[i];

            long start = spectrum.startSampleIndex;
            long end = spectrum.endSampleIndex;

            if (start >= blockEndSampleIndex) {
                break;
            }

            if (end < 0 || end > blockStartSampleIndex) {
                voiceTransformParameterHashes.add(spectrum.hashedWarpingSlopes);
            }
        }

        return voiceTransformParameterHashes;
    }

    protected byte[] hashBlockWithParameters(byte[] blockSampleHash, byte[] parameterHash) throws NoSuchAlgorithmException {
        byte[] concatenatedHash = new byte[blockSampleHash.length + parameterHash.length];

        System.arraycopy(blockSampleHash, 0, concatenatedHash, 0, blockSampleHash.length);
        System.arraycopy(parameterHash, 0, concatenatedHash, blockSampleHash.length, parameterHash.length);

        return Hash.hash("SHA1", concatenatedHash);
    }
}
