package com.example.overo.audio.codec;

import android.util.Log;

public class AACDecoder {
    static {
        System.loadLibrary("FAAD2");
    }

    private native void decode(String in_file_path, String out_file_path);

    public void AACDecode(String in_file_path, String out_file_path){
        Log.e("input", in_file_path);
        Log.e("output", out_file_path);
        decode(in_file_path, out_file_path);
    }
}
