package com.example.overo.overo.audio;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;

public class AudioHash {

    byte[] hash;

    public AudioHash(byte[] hash) {
        this.hash = hash;
    }

    public void store(File storage, String file) {
        try {
            FileOutputStream fileOutputStream = new FileOutputStream(new File(storage, file), false);
            BufferedOutputStream bufferedOutputStream = new BufferedOutputStream(fileOutputStream);

            // name
            // timestamp
            // hash
            bufferedOutputStream.write(hash);
            bufferedOutputStream.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void dispose() {
        hash = null;
    }
}
