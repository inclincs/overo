package com.example.overo;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.util.Log;
import android.view.SurfaceHolder;
import android.view.SurfaceView;

import androidx.annotation.NonNull;

import java.util.ArrayList;

public class RecordingSurfaceView extends SurfaceView implements SurfaceHolder.Callback {

    final SurfaceHolder holder;
    RenderingThread thread;
    int width;
    int height;

    public RecordingSurfaceView(Context context) {
        super(context);

        holder = getHolder();
        holder.addCallback(this);
    }

    public void start() {
        thread = new RenderingThread();
        thread.start();
    }

    public void stop() {
        thread.running = false;
        try {
            thread.join();
        } catch (InterruptedException e) {
            e.printStackTrace();
        }
    }

    @Override
    public void surfaceCreated(@NonNull SurfaceHolder holder) {

    }

    @Override
    public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {
        this.width = width;
        this.height = height;
    }

    @Override
    public void surfaceDestroyed(@NonNull SurfaceHolder holder) {

    }

    class RenderingThread extends Thread {

        boolean running;

        Paint paint = new Paint();

        AudioRecord ar;
        short[] buffer;
        ArrayList<Short> signals = new ArrayList<>();

        final int frequency = 10; // 초당 10번 signal 생성
        final int signalCount = 3; // 1번당 3개의 signal 생성
        final float speed = 600; // 초당 20px 진행 == $(frequency)개당 $(speed)px 진행
        int maxSignalCount;
        float lengthPerSignal;
        final float barWidthRatio = 0.5f;

        long elapsedTime;
        short targetTime;
        float progressedLength;
        int originX, originY;

        void init() {
            int minSize = AudioRecord.getMinBufferSize(8000, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT);
            ar = new AudioRecord(MediaRecorder.AudioSource.MIC, 8000, AudioFormat.CHANNEL_CONFIGURATION_MONO, AudioFormat.ENCODING_PCM_16BIT, minSize);

            buffer = new short[minSize]; // 512

            ar.startRecording();

            elapsedTime = 0;

            maxSignalCount = (int) Math.ceil(width * frequency * signalCount / speed); // width 만큼의 길이에 몇개의 signal이 들어가는가?
            lengthPerSignal = (float) width / maxSignalCount; // 1개 생성될 때 지나가는 길이 = bar의 가로 길이 + 간격[px]

            originX = width + (int) Math.ceil(lengthPerSignal * signalCount);
            originY = height / 2;

            targetTime = 1000 / frequency;
        }

        void update(long deltaTime) {
            elapsedTime += deltaTime;
            progressedLength += deltaTime / 1000.0 * speed;

            if (elapsedTime > targetTime) {
                ar.read(buffer, 0, buffer.length);

                int lengthPerSignalCount = buffer.length / signalCount;
                short mean = 10;

                for (int i = 0; i < signalCount; i++) {
                    int offset = lengthPerSignalCount * i;

                    for (int j = 0; j < lengthPerSignalCount; j++) {
                        mean += buffer[offset + j];
                    }

                    mean /= buffer.length;

                    signals.add(mean);
                }

//                for (int i = 0; i < signalCount; i++) {
//                    signals.add((short) ((Math.random() * 10 + 1)));
//                }

                if (signals.size() > maxSignalCount + 3) {
                    signals.remove(0);
                    signals.remove(0);
                    signals.remove(0);
                    progressedLength = width + 50;
                }

                elapsedTime -= targetTime;
            }
        }

        void render(Canvas canvas) {
            paint.setColor(Color.argb(255, 255, 0, 0));

            for (int i = 0; i < signals.size(); i++) {
                int barX = (int) (originX - progressedLength + i * lengthPerSignal);
                int barY = signals.get(i) + 2;

                canvas.drawRect(
                        barX, originY - barY,
                        barX + lengthPerSignal * barWidthRatio, originY + barY, paint);
            }

            paint.setColor(Color.GRAY);
            canvas.drawLine(0, originY, width, originY, paint);
        }

        @Override
        public void run() {
            running = true;

            init();

            Canvas canvas;

            long lastTime = System.currentTimeMillis();

            while (running) {
                long currentTime = System.currentTimeMillis();
                long deltaTime = currentTime - lastTime;

                update(deltaTime);

                lastTime = currentTime;

                canvas = holder.lockCanvas();

                try {
                    synchronized (holder) {
                        canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);

                        render(canvas);
                    }
                } finally {
                    if (canvas != null) {
                        holder.unlockCanvasAndPost(canvas);
                    }
                }
            }

            ar.stop();
        }
    }
}
