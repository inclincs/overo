package com.example.overo;

import androidx.annotation.NonNull;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class RecordingData {

    private String name;
    private final String fileName;
    private final Date date;
    private final long totalTime;

    public RecordingData(String name, String fileName, Date date, long totalTime) {
        this.name = name;
        this.fileName = fileName;
        this.date = date;
        this.totalTime = totalTime;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getName() {
        return name;
    }
    public String getFileName() {
        return fileName;
    }
    public Date getDate() {
        return date;
    }
    public long getTotalTime() {
        return totalTime;
    }

    @NonNull
    @Override
    public String toString() {
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss", Locale.KOREA);

        return String.format("%s,%s,%s,%s", name, fileName, sdf.format(date), totalTime);
    }

    public static RecordingData fromString(String data) {
        String[] items = data.split(",");

        SimpleDateFormat formatter = new SimpleDateFormat("yyyy-MM-dd hh:mm:ss", Locale.KOREA);

        Date date;

        try {
            date = formatter.parse(items[2]);
        } catch (ParseException e) {
            e.printStackTrace();
            return null;
        }

        return new RecordingData(items[0], items[1], date, Long.parseLong(items[3]));
    }
}
