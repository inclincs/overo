package com.example.overo.overo.process.realtime;

import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.os.Build;
import android.util.Log;

import com.example.overo.R;
import com.example.overo.RecordingData;

import java.io.File;
import java.io.IOException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.Locale;

public class OveroRecorder {

    public static class Result {
        public Date recordingDate;
        public String recordingFileName;
        public long startRecordingTime;
        public long duration;

        public Result(Date recordingDate, String recordingFileName, long startRecordingTime, long duration) {
            this.recordingDate = recordingDate;
            this.recordingFileName = recordingFileName;
            this.startRecordingTime = startRecordingTime;
            this.duration = duration;
        }
    }

    Result result;

    MediaRecorder recorder;
    String audioFilePath;

    public void dispose() {
        if (recorder != null) {
            recorder.stop();
            recorder.release();
            recorder = null;
        }
    }

    public boolean isRecording() {
        return recorder != null;
    }

    public void start(File audioStorage) {
        if (isRecording()) {
            return;
        }


        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd_HHmmss", Locale.KOREA);

        Date recordingDate = new Date(System.currentTimeMillis());
        String recordingFileName = formatter.format(recordingDate);
        long startRecordingTime = System.currentTimeMillis();

        result = new Result(
                recordingDate, recordingFileName, startRecordingTime, 0
        );


        File file = new File(audioStorage, recordingFileName + "_origin.aac");

        audioFilePath = file.getAbsolutePath();

        Log.d("startRecording", "저장할 파일: " + audioFilePath);


        recorder = new MediaRecorder();

        recorder.setAudioSamplingRate(16000);
        recorder.setAudioChannels(1);
        recorder.setAudioSource(MediaRecorder.AudioSource.MIC);
        recorder.setOutputFormat(MediaRecorder.OutputFormat.AAC_ADTS);
        recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC);

        recorder.setOutputFile(audioFilePath);

        try {
            recorder.prepare();
        } catch (Exception e) {
            e.printStackTrace();
        }

        recorder.start();
    }

    public Result stop() {
        if (recorder == null) {
            return null;
        }

        recorder.stop();
        recorder.release();
        recorder = null;

        MediaPlayer mp = new MediaPlayer();

        try {
            mp.setDataSource(audioFilePath);
            mp.prepare();

            result.duration = mp.getDuration();

            mp.release();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return result;
    }
}

