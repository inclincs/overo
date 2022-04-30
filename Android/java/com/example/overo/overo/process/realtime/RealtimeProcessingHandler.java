package com.example.overo.overo.process.realtime;

import android.os.Handler;
import android.os.HandlerThread;

import androidx.annotation.NonNull;

import java.io.File;
import java.security.NoSuchAlgorithmException;

public class RealtimeProcessingHandler {

    public static class Message {

        File storage;
        String audioName;

        public Message(File storage, String audioName) {
            this.storage = storage;
            this.audioName = audioName;
        }
    }

    HandlerThread thread;
    Handler handler;

    public RealtimeProcessingHandler() {
        thread = new HandlerThread("Overo Realtime Processing Thread");
        thread.start();

        handler = new Handler(thread.getLooper()) {
            @Override
            public void handleMessage(@NonNull android.os.Message msg) {
                Message message = (Message) msg.obj;

                try {
                    OveroRealtimeProcessor processor = new OveroRealtimeProcessor();
                    
                    processor.process(message.storage, message.audioName);
                } catch (NoSuchAlgorithmException e) {
                    e.printStackTrace();
                }
            }
        };
    }

    public void dispose() {
        thread.quit();
    }

    public void request(Message message) {
        android.os.Message m = android.os.Message.obtain(handler, 0);

        m.obj = message;

        handler.sendMessage(m);
    }
}
