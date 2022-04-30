package com.example.overo;

import android.animation.Animator;
import android.animation.ValueAnimator;
import android.app.AlertDialog;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.net.Uri;
import android.text.InputType;
import android.util.Log;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.LinearLayout;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.ToggleButton;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.io.File;
import java.io.IOException;
import java.sql.Timestamp;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Locale;

public class RecordingItemViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener, SeekBar.OnSeekBarChangeListener, MediaPlayer.OnCompletionListener {

    private final TextView textViewRecordingName;
    private final TextView textViewDate;
    private final TextView textViewTotalTime;

    private final LinearLayout linearLayoutInformation;
    private final SeekBar seekBarRecording;
    private final TextView textViewPlayTime;
    private final TextView textViewReversePlayTime;
    private final ToggleButton buttonPlay;

    private final RecordingRecyclerViewAdapter adapter;
    private final RecordingPlayer player;
    private long totalTime;

    public RecordingItemViewHolder(@NonNull RecordingRecyclerViewAdapter adapter, @NonNull View itemView) {
        super(itemView);

        this.adapter = adapter;

        textViewRecordingName = itemView.findViewById(R.id.textViewRecordingName);
        textViewDate = itemView.findViewById(R.id.textViewDate);
        textViewTotalTime = itemView.findViewById(R.id.textViewTotalTime);

        linearLayoutInformation = itemView.findViewById(R.id.linearLayoutInformation);

        seekBarRecording = linearLayoutInformation.findViewById(R.id.seekBarRecording);
        textViewPlayTime = linearLayoutInformation.findViewById(R.id.textViewPlayTime);
        textViewReversePlayTime = linearLayoutInformation.findViewById(R.id.textViewReversePlayTime);

        buttonPlay = linearLayoutInformation.findViewById(R.id.toggleButtonPlay);
        ImageButton buttonDelete = linearLayoutInformation.findViewById(R.id.imageButtonDelete);


        itemView.setOnClickListener(this);
        textViewRecordingName.setOnClickListener(this);
        seekBarRecording.setOnSeekBarChangeListener(this);
        buttonPlay.setOnClickListener(this);
        buttonDelete.setOnClickListener(this);


        linearLayoutInformation.getLayoutParams().height = 0;
        linearLayoutInformation.setAlpha(0);

        player = new RecordingPlayer(adapter, seekBarRecording, buttonPlay);
    }

    void reset() {
        seekBarRecording.setProgress(0);
    }

    void onBind(RecordingItemViewHolder holder, int position) {
        setVisibilityOfInformation(position);


        RecordingData data = adapter.getRecordingData(position);

        textViewRecordingName.setText(data.getName());

        SimpleDateFormat simpleDateFormat = new SimpleDateFormat("yyyy. MM. dd", Locale.KOREA);
        textViewDate.setText(simpleDateFormat.format(data.getDate()));

        totalTime = data.getTotalTime();

        Timestamp tsTotalTime = new Timestamp(totalTime);
        String textTotalTime = new SimpleDateFormat("mm:ss", Locale.KOREA).format(tsTotalTime);
        textViewTotalTime.setText(textTotalTime);

        seekBarRecording.setProgress(0);
        seekBarRecording.setMax((int) totalTime);

        textViewPlayTime.setText("00:00");

        Timestamp tsReversePlayTime = new Timestamp(totalTime);
        String textReversePlayTime = new SimpleDateFormat("-mm:ss", Locale.KOREA).format(tsReversePlayTime);
        textViewReversePlayTime.setText(textReversePlayTime);
    }

    void setVisibilityOfInformation(int position) {
        if (adapter.isSelectedItem(position)) {
            linearLayoutInformation.measure(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);

            linearLayoutInformation.getLayoutParams().height = linearLayoutInformation.getMeasuredHeight();
        }
        else {
            linearLayoutInformation.getLayoutParams().height = 0;
        }

        linearLayoutInformation.requestLayout();
    }

    void onBind(@NonNull RecordingItemViewHolder holder, int position, @NonNull List<Object> payloads) {
        for (Object payload: payloads) {
            if (payload instanceof String) {
                String type = (String) payload;

                if (type.equals("expand")) {
                    animate(true);
                }
                else if (type.equals("shrink")) {
                    animate(false);
                }
            }
        }
    }

    private void animate(final boolean isExpanded) {
        linearLayoutInformation.measure(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);

        final int height = linearLayoutInformation.getMeasuredHeight();

        ValueAnimator valueAnimator = isExpanded ? ValueAnimator.ofFloat(0, 1.0f) : ValueAnimator.ofFloat(1.0f, 0);

        valueAnimator.setDuration(200);
        valueAnimator.addUpdateListener(new ValueAnimator.AnimatorUpdateListener() {
            @Override
            public void onAnimationUpdate(ValueAnimator animation) {
                float value = (float) animation.getAnimatedValue();

                linearLayoutInformation.getLayoutParams().height = (int) (value * height);
                linearLayoutInformation.requestLayout();
                linearLayoutInformation.setAlpha(value);
            }
        });
        valueAnimator.addListener(new Animator.AnimatorListener() {
            @Override
            public void onAnimationStart(Animator animation) {}

            @Override
            public void onAnimationEnd(Animator animation) {
                if (!isExpanded) {
                    reset();
                }
            }

            @Override
            public void onAnimationCancel(Animator animation) {}

            @Override
            public void onAnimationRepeat(Animator animation) {}
        });

        valueAnimator.start();
    }

    @Override
    public void onClick(View v) {
        switch (v.getId()) {
            case R.id.toggleButtonPlay:
                togglePlayButton();
                break;
            case R.id.imageButtonDelete:
                showDeleteRecordingConfirmDialog();
                break;
            case R.id.textViewRecordingName:
                showChangeRecordingNameDialog();
                break;
            default:
                selectRecording();
                break;
        }
    }

    void togglePlayButton() {
         player.toggle();
    }

    void showDeleteRecordingConfirmDialog() {
        AlertDialog.Builder builder = new AlertDialog.Builder(itemView.getContext());

        builder.setTitle(R.string.remove_recording);
        builder.setPositiveButton("Yes", (dialog, which) -> adapter.delete(getAdapterPosition()));
        builder.setNegativeButton("No", (dialog, which) -> dialog.cancel());

        builder.show();
    }

    void showChangeRecordingNameDialog() {
        int itemIndex = getAdapterPosition();

        if (adapter.isSelectedItem(itemIndex)) {
            AlertDialog.Builder builder = new AlertDialog.Builder(itemView.getContext());

            builder.setTitle(R.string.change_recording_name);

            final EditText input = new EditText(itemView.getContext());
            input.setInputType(InputType.TYPE_CLASS_TEXT);
            input.setText(textViewRecordingName.getText());
            builder.setView(input);

            builder.setPositiveButton("OK", (dialog, which) -> changeRecordingName(input.getText().toString()));
            builder.setNegativeButton("Cancel", (dialog, which) -> dialog.cancel());

            builder.show();
        }
        else {
            adapter.select(itemIndex);
        }
    }

    void changeRecordingName(String name) {
        textViewRecordingName.setText(name);

        try {
            RecordingData data = adapter.getSelectedRecordingData();
            data.setName(name);

            adapter.storeRecordingList();
        } catch (NoSelectedRecordingException e) {
            e.printStackTrace();
        }
    }

    void selectRecording() {
        adapter.select(getAdapterPosition());

        player.release();

        if (adapter.isSelected()) {
            try {
                player.load(itemView.getContext(), getSelectedRecordingFileUri(), this);
            } catch (NoSelectedRecordingException e) {
                e.printStackTrace();
            }
        }
    }

    Uri getSelectedRecordingFileUri() throws NoSelectedRecordingException {
        RecordingData data = adapter.getSelectedRecordingData();

        String fileName = data.getFileName();

        File file = new File(itemView.getContext().getFilesDir(), "data/audio/" + fileName + "_origin.aac");

        return Uri.fromFile(file);
    }

    @Override
    public void onProgressChanged(SeekBar seekBar, int progress, boolean fromUser) {
        setPlayTime(progress);
        setReversePlayTime(progress);
    }

    void setPlayTime(int playTime) {
        Timestamp tsPlayTime = new Timestamp(playTime);
        String textPlayTime = new SimpleDateFormat("mm:ss", Locale.KOREA).format(tsPlayTime);
        textViewPlayTime.setText(textPlayTime);
    }

    void setReversePlayTime(int playTime) {
        Timestamp tsReversePlayTime = new Timestamp(totalTime - playTime);
        String textReversePlayTime = new SimpleDateFormat("-mm:ss", Locale.KOREA).format(tsReversePlayTime);
        textViewReversePlayTime.setText(textReversePlayTime);
    }


    @Override
    public void onStartTrackingTouch(SeekBar seekBar) {
        player.pause();
    }

    @Override
    public void onStopTrackingTouch(SeekBar seekBar) {
        player.seekTo(seekBar.getProgress());

        if (player.isPlaying) {
            player.play();
        }
    }

    @Override
    public void onCompletion(MediaPlayer mp) {
        player.stop();

        buttonPlay.setChecked(false);
    }
}