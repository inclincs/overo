package com.example.overo.overo.process.realtime;

import android.os.Handler;
import android.os.HandlerThread;
import android.os.Message;
import android.os.SystemClock;
import android.util.Log;

import androidx.annotation.NonNull;

import com.example.overo.overo.audio.Audio;
import com.example.overo.overo.audio.AudioHash;
import com.example.overo.overo.Configuration;
import com.example.overo.overo.audio.OriginalAudio;
import com.example.overo.overo.audio.SpeakerProtectedAudio;
import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;
import com.example.overo.overo.voice.protection.SpeakerProtector;

import java.io.File;
import java.security.NoSuchAlgorithmException;

import static com.example.overo.overo.Configuration.BLOCK_SIZE;

public class OveroRealtimeProcessor {

//    static class RealtimeMessage {
//
//        File storage;
//        String audioName;
//
//        RealtimeMessage(File storage, String audioName) {
//            this.storage = storage;
//            this.audioName = audioName;
//        }
//    }
//
//    HandlerThread thread;
//    Handler handler;
//
//    public OveroRealtimeProcessor() {
//        thread = new HandlerThread("Overo Realtime Processing Thread");
//        thread.start();
//
//        handler = new Handler(thread.getLooper()) {
//            @Override
//            public void handleMessage(@NonNull Message msg) {
//                RealtimeMessage message = (RealtimeMessage) msg.obj;
//
//                try {
//                    protectOriginalAudio(message.storage, message.audioName);
//                } catch (NoSuchAlgorithmException e) {
//                    e.printStackTrace();
//                }
//            }
//        };
//    }
//
//    public void dispose() {
//        thread.quit();
//    }
//
//    public void protect(File storage, String audioName) {
//        Message message = Message.obtain(handler, 0);
//
//        message.obj = new RealtimeMessage(storage, audioName);
//
//        handler.sendMessage(message);
//    }

    protected void process(File storage, String audioName) throws NoSuchAlgorithmException {
        long startTime = SystemClock.elapsedRealtime();

        Audio audio = loadOriginalAudio(storage, audioName);

        SpeakerProtector.Result result = SpeakerProtector.protect(audio);


        SpeakerProtectedAudio speakerProtectedAudio = result.speakerProtectedAudio;
        VoiceTransformParameter voiceTransformParameter = result.voiceTransformParameter;


        storeSpeakerProtectedAudio(storage, audioName, speakerProtectedAudio);

        long hashStartTime = SystemClock.elapsedRealtime();
        AudioHash audioHash = generateAudioHash(storage, audioName, voiceTransformParameter);
        long hashEndTime = SystemClock.elapsedRealtime();
        storeAudioHash(storage, audioName, audioHash);

        storeVoiceTransformParameter(storage, audioName, voiceTransformParameter);

        long endTime = SystemClock.elapsedRealtime();
        long elapsedTime = endTime - startTime;
        double seconds = elapsedTime / 1000.0;
        long hashElapsedTime = hashEndTime - hashStartTime;
        double hashSeconds = hashElapsedTime / 1000.0;
        Log.e("Overo", "Realtime Processing: " + seconds);
        Log.e("Overo", "Realtime Processing - Hash: " + hashSeconds);

        speakerProtectedAudio.dispose();
    }
    protected Audio loadOriginalAudio(File storage, String audioName) {
        return OriginalAudio.load(storage, audioName);
    }

    protected void storeSpeakerProtectedAudio(File storage, String audioName, SpeakerProtectedAudio speakerProtectedAudio) {
        speakerProtectedAudio.store(storage, audioName);
        speakerProtectedAudio.dispose();
    }

    protected AudioHash generateAudioHash(File storage, String audioName, VoiceTransformParameter voiceTransformParameter) throws NoSuchAlgorithmException {
        SpeakerProtectedAudio speakerProtectedAudio = SpeakerProtectedAudio.load(storage, audioName);

        return speakerProtectedAudio.hash(BLOCK_SIZE, voiceTransformParameter);
    }

    protected void storeAudioHash(File storage, String audioName, AudioHash audioHash) {
        File metaStorage = new File(storage, "meta");

        audioHash.store(metaStorage, audioName + ".adh");
        audioHash.dispose();
    }

    protected void storeVoiceTransformParameter(File storage, String audioName, VoiceTransformParameter voiceTransformParameter) {
        File metaStorage = new File(storage, "meta");

        voiceTransformParameter.store(metaStorage, audioName + ".vtp");
        voiceTransformParameter.dispose();
    }
}
