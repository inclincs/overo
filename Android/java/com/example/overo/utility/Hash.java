package com.example.overo.utility;

import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;

public class Hash {

    MessageDigest messageDigest;

    public Hash(String hashName) throws NoSuchAlgorithmException {
        messageDigest = MessageDigest.getInstance(hashName);
    }

    public byte[] digest() {
        return messageDigest.digest();
    }

    public byte[] digest(byte[] input) {
        return messageDigest.digest(input);
    }

    public void update(byte[] input) {
        messageDigest.update(input);
    }

    public static byte[] hash(String hashName, byte[] input) throws NoSuchAlgorithmException {
        return MessageDigest.getInstance(hashName).digest(input);
    }
}
