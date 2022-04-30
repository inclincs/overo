package com.example.overo;

import android.content.Context;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.util.Log;
import android.widget.SeekBar;
import android.widget.ToggleButton;

import java.io.IOException;

public class RecordingPlayer implements MediaPlayer.OnPreparedListener {

    RecordingRecyclerViewAdapter adapter;
    SeekBar seekBar;
    ToggleButton button;

    MediaPlayer mediaPlayer;
    RecordingPlayerThread thread;

    boolean isPlaying;

    public RecordingPlayer(RecordingRecyclerViewAdapter adapter, SeekBar seekBar, ToggleButton button) {
        this.adapter = adapter;
        this.seekBar = seekBar;
        this.button = button;
    }

    public void release() {
        if (mediaPlayer != null) {
            if (thread != null) {
                thread.running = false;

                if (thread.paused) {
                    thread.onResume();
                }

                try {
                    thread.join();
                } catch (InterruptedException e) {
                    e.printStackTrace();
                } finally {
                    thread = null;
                }
            }

            mediaPlayer.release();
            mediaPlayer = null;
        }
    }

    public void load(Context context, Uri uri, MediaPlayer.OnCompletionListener listener) {
        button.setEnabled(false);

        release();

        mediaPlayer = new MediaPlayer();
        mediaPlayer.setAudioStreamType(AudioManager.STREAM_MUSIC);

        try {
            mediaPlayer.setOnCompletionListener(listener);
            mediaPlayer.setDataSource(context, uri);
            mediaPlayer.setOnPreparedListener(this);
            mediaPlayer.prepareAsync();

            isPlaying = false;
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void toggle() {
        if (isPlaying) {
            stop();
        }
        else {
            play();
        }
    }

    public void pause() {
        if (mediaPlayer != null) {
            thread.onPause();
            mediaPlayer.pause();
        }
    }

    public void stop() {
        if (mediaPlayer != null) {
            thread.onPause();
            mediaPlayer.pause();

            isPlaying = false;
        }
    }

    public void play() {
        if (mediaPlayer != null) {
            thread.onResume();
            mediaPlayer.start();

            isPlaying = true;
        }
    }

    public void seekTo(int progress) {
        if (mediaPlayer != null) {
            mediaPlayer.seekTo(progress);
        }
    }

    @Override
    public void onPrepared(MediaPlayer mp) {
        thread = new RecordingPlayerThread(mediaPlayer, this.seekBar);
        thread.start();
        thread.onPause();

        button.setEnabled(true);

    }
}
