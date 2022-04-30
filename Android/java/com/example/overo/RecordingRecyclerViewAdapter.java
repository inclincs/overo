package com.example.overo;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import java.io.File;
import java.util.List;

public class RecordingRecyclerViewAdapter extends RecyclerView.Adapter<RecordingItemViewHolder> {

    private final Context context;

    private RecordingList list;

    private int selectedPosition = -1;

    public RecordingRecyclerViewAdapter(Context context) {
        this.context = context;
    }

    @NonNull
    @Override
    public RecordingItemViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext()).inflate(R.layout.recording_item, parent, false);

        return new RecordingItemViewHolder(this, view);
    }

    @Override
    public void onViewRecycled(@NonNull RecordingItemViewHolder holder) {
        super.onViewRecycled(holder);
    }

    @Override
    public void onBindViewHolder(@NonNull RecordingItemViewHolder holder, int position) {
        holder.onBind(holder, position);
    }

    @Override
    public void onBindViewHolder(@NonNull RecordingItemViewHolder holder, int position, @NonNull List<Object> payloads) {
        super.onBindViewHolder(holder, position, payloads);

        holder.onBind(holder, position, payloads);
    }

    @Override
    public int getItemCount() {
        return list.size();
    }


    void bind(RecordingList list) {
        this.list = list;
    }


    public RecordingData getSelectedRecordingData() throws NoSelectedRecordingException {
        if (isSelected()) {
            return list.get(selectedPosition);
        }

        throw new NoSelectedRecordingException();
    }

    public RecordingData getRecordingData(int index) {
        return list.get(index);
    }


    public void select(int position) {
        if (isSelected()) {
            notifyItemChanged(selectedPosition, "shrink");
        }


        position = position >= list.size() ? list.size() - 1 : (position < 0 ? -1 : position);

        if (position == -1 || isSelectedItem(position)) {
            selectedPosition = -1;
        }
        else {
            notifyItemChanged(position, "expand");

            selectedPosition = position;
        }
    }

    boolean isSelected() {
        return selectedPosition > -1;
    }

    boolean isSelectedItem(int position) {
        return selectedPosition == position;
    }


    public void delete(int position) {
        if (position < 0 || list.size() <= position) {
            throw new IndexOutOfBoundsException();
        }


        RecordingData data = list.remove(position);
        list.store();

        deleteFiles(data.getFileName());


        selectedPosition = -1;

        notifyDataSetChanged();
    }

    public void deleteFiles(String fileName) {
        File overoStorage = new File(context.getFilesDir(), "data/");

        String[] targets = {
                "audio/" + fileName + "_origin.aac",
                "audio/" + fileName + ".aac",
                "meta/" + fileName + ".adh",
                "meta/" + fileName + ".vtp",
                "temp/" + fileName + "_origin.wav",
                "temp/" + fileName + ".wav"
        };

        for (String target: targets) {
            new File(overoStorage, target).delete();
        }
    }

    public void storeRecordingList() {
        list.store();
    }
}
