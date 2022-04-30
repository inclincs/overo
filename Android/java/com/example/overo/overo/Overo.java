package com.example.overo.overo;

import com.example.overo.overo.process.realtime.RealtimeProcessingHandler;
import com.example.overo.overo.process.realtime.OveroRecorder;

import java.io.File;

public class Overo {

    static class OveroStorage {

        File root;
        File data;
        File audio;
        File meta;
        File temp;

        public OveroStorage(File root) {
            this.root = root;

            if (!root.exists()) {
                throw new IllegalArgumentException();
            }

            data = new File(root, "data");
            audio = new File(root, "data/audio");
            meta = new File(root, "data/meta");
            temp = new File(root, "data/temp");

            data.mkdirs();
            audio.mkdirs();
            meta.mkdirs();
            temp.mkdirs();
        }
    }

    OveroStorage storage;
    OveroRecorder recorder;
    RealtimeProcessingHandler realtimeProcessingMessageHandler;

    public void initialize(File rootStorage) {
        storage = new OveroStorage(rootStorage);
        recorder = new OveroRecorder();
        realtimeProcessingMessageHandler = new RealtimeProcessingHandler();
    }


    public boolean isRecording() {
        return recorder.isRecording();
    }

    public void startRecording() {
        if (recorder.isRecording()) {
            return;
        }

        recorder.start(storage.audio);
    }

    public OveroRecorder.Result stopRecording() {
        OveroRecorder.Result result = recorder.stop();

        // Need to verify
        RealtimeProcessingHandler.Message message = new RealtimeProcessingHandler.Message(
                storage.data, result.recordingFileName);

        realtimeProcessingMessageHandler.request(message);

        return result;
    }


    public void dispose() {
        recorder.dispose();
        realtimeProcessingMessageHandler.dispose();
    }
}
