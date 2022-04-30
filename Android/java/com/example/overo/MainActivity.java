package com.example.overo;

import androidx.appcompat.app.AppCompatActivity;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.SurfaceView;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.example.overo.overo.Overo;
import com.example.overo.overo.process.realtime.OveroRealtimeProcessor;
import com.example.overo.overo.process.realtime.OveroRecorder;
import com.example.overo.utility.Binarization;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.Random;
import java.util.Timer;
import java.util.TimerTask;

import static com.example.overo.utility.Binarization.binarize;

public class MainActivity extends AppCompatActivity {

    RecordingRecyclerViewAdapter adapter;
    RecordingList recordingList;
    RecordingSurfaceView recordingSurfaceView;

    Overo overo;
    Timer timer;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);

        initializeViews();

        loadRecordings();
        showRecordings();

        initializeOvero();
    }

    protected void initializeViews() {
        RecyclerView recyclerView = findViewById(R.id.recyclerViewRecordings);

        LinearLayoutManager linearLayoutManager = new LinearLayoutManager(this);
        recyclerView.setLayoutManager(linearLayoutManager);

        adapter = new RecordingRecyclerViewAdapter(this);
        recyclerView.setAdapter(adapter);

        LinearLayout linearLayoutRecordingProgress = findViewById(R.id.linearLayoutRecordingProgress);
        recordingSurfaceView = new RecordingSurfaceView(this);
        linearLayoutRecordingProgress.addView(recordingSurfaceView);
        recordingSurfaceView.getLayoutParams().height = 200;

        Button buttonStartRecording = findViewById(R.id.buttonStartRecording);
        Button buttonStopRecording = findViewById(R.id.buttonStopRecording);

        buttonStartRecording.setOnClickListener(this::startRecording);
        buttonStopRecording.setOnClickListener(this::stopRecording);
    }

    protected void loadRecordings() {
        File recordingInformationFile = new File(getApplicationContext().getFilesDir(), "recordings.txt");
        String recordingInformationFilePath = recordingInformationFile.getAbsolutePath();

        recordingList = RecordingList.load(recordingInformationFilePath);
    }

    protected void showRecordings() {
        adapter.bind(recordingList);
        adapter.notifyDataSetChanged();
    }

    protected void initializeOvero() {
        overo = new Overo();

        File storage = getApplicationContext().getFilesDir();

        overo.initialize(storage);
    }

    @Override
    protected void onDestroy() {
        overo.dispose();

        super.onDestroy();
    }

    protected void startRecording(View v) {
        if (overo.isRecording()) {
            return;
        }

        adapter.select(-1);
        // adapter touch lock

        Toast.makeText(getApplicationContext(), "녹음을 시작합니다.", Toast.LENGTH_SHORT).show();


        overo.startRecording();


        TextView textView = findViewById(R.id.textViewRecordingTime);
        textView.setText("00:00");

        long startTime = System.currentTimeMillis();

        SimpleDateFormat formatter = new SimpleDateFormat("mm:ss", Locale.KOREA);

        TimerTask task = new TimerTask() {
            @Override
            public void run() {
                String t = formatter.format(System.currentTimeMillis() - startTime);
                runOnUiThread(() -> textView.setText(t));
            }
        };

        timer = new Timer();
        timer.schedule(task, 0, 1000);

        recordingSurfaceView.start();
    }

    protected void stopRecording(View v) {
        if (!overo.isRecording()) {
            return;
        }

        Toast.makeText(getApplicationContext(), "녹음을 종료합니다.", Toast.LENGTH_SHORT).show();

        recordingSurfaceView.stop();

        timer.cancel();
        timer = null;

        OveroRecorder.Result result = overo.stopRecording();

        RecordingData data = new RecordingData(
                getResources().getString(R.string.new_recording),
                result.recordingFileName,
                result.recordingDate,
                result.duration
        );

        recordingList.add(0, data);
        recordingList.store();

        adapter.notifyDataSetChanged();
    }
}