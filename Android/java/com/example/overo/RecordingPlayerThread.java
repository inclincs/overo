package com.example.overo;

import android.media.MediaPlayer;
import android.widget.SeekBar;

public class RecordingPlayerThread extends Thread {

    MediaPlayer mediaPlayer;
    SeekBar seekBar;

    boolean running;
    boolean paused;
    final Object lock;

    public RecordingPlayerThread(MediaPlayer mediaPlayer, SeekBar seekBar) {
        this.mediaPlayer = mediaPlayer;
        this.seekBar = seekBar;

        lock = new Object();
    }

    @Override
    public void run() {
        running = true;

        while (running) {
            synchronized (lock) {
                while (paused) {
                    try {
                        lock.wait();
                    } catch (InterruptedException ignored) {}
                }
            }

            seekBar.setProgress(mediaPlayer.getCurrentPosition());
        }
    }

    void onPause() {
        synchronized (lock) {
            paused = true;
        }
    }
    void onResume() {
        synchronized (lock) {
            paused = false;
            lock.notifyAll();
        }
    }
}