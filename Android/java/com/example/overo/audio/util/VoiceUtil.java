package com.example.overo.audio.util;

import java.util.ArrayList;
import java.util.List;

public class VoiceUtil {
    public static List<Integer> getVoicedElementIndex(double[] x){
        List<Integer> voicedSampleIndex = new ArrayList<>();
        for (int i = 0; i < x.length; i++) {
            if (x[i] != 0.0) {
                voicedSampleIndex.add(i);
            }
        }
        return voicedSampleIndex;
    }

    public static List<Boolean> getVoicedMask(double[] x){
        List<Boolean> voicedMask = new ArrayList<>();
        for (int i = 0; i < x.length; i++) {
            if (x[i] != 0.0) {
                voicedMask.add(true);
            } else {
                voicedMask.add(false);
            }
        }
        return voicedMask;
    }

    public static double[] getVoicedElements(double[] x){
        List<Integer> voicedElementIndex = VoiceUtil.getVoicedElementIndex(x);

        double[] voicedElements = new double[voicedElementIndex.size()];
        for(int i = 0; i < voicedElements.length; i++){
            voicedElements[i] = x[voicedElementIndex.get(i).intValue()];
        }

        return voicedElements;
    }
}
