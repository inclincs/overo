package com.example.overo.audio.codec;

public class AACEncoder {
    static {
        System.loadLibrary("FAAC");
    }

    private native void encode(String in_file_path, String out_file_path);

    public void AACEncode(String in_file_path, String out_file_path) {
        encode(in_file_path, out_file_path);
    }
}
