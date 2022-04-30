package com.example.overo;

import android.util.Log;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;

public class RecordingList extends ArrayList<RecordingData> {

    String filePath;

    public RecordingList(String filePath) {
        super();

        this.filePath = filePath;
    }

    public static RecordingList load(String filePath) {
        RecordingList list = new RecordingList(filePath);

        try (FileReader fileReader = new FileReader(filePath)) {
            BufferedReader bufferedReader = new BufferedReader(fileReader);

            while (bufferedReader.ready()) {
                String line = bufferedReader.readLine();

                RecordingData data = RecordingData.fromString(line);

                if (data != null) {
                    list.add(data);
                }
            }

            bufferedReader.close();
        } catch (IOException e) {
            e.printStackTrace();
        }

        return list;
    }

    public void store() {
        try (FileWriter fileWriter = new FileWriter(filePath)) {
            BufferedWriter bufferedWriter = new BufferedWriter(fileWriter);

            int size = size();

            for (int i = 0; i < size; i++) {
                bufferedWriter.write(get(i).toString());

                if (i < size - 1) {
                    bufferedWriter.newLine();
                }
            }

            bufferedWriter.close();
        } catch (IOException e) {
            Log.e("RecordingList.store", e.getMessage());
            e.printStackTrace();
        }
    }
}
