package com.example.overo.overo;

public class Configuration {
    enum RealtimeProcessingSource {
        None, MIC, File
    }

    RealtimeProcessingSource source;

    public int blockSize;

    public static final int BLOCK_SIZE = 1024;
}
