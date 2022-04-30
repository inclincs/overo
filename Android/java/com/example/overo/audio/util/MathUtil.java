package com.example.overo.audio.util;

public class MathUtil {
    public static double mean(double[] x){
        double sum = 0.0;
        for (int i = 0; i < x.length; i++){
            sum += x[i];
        }
        return sum / x.length;
    }

    public static double std(double[] x){
        double x_mean = mean(x);

        double sum_variation = 0.0;
        for (int i = 0; i < x.length; i++){
            sum_variation += Math.pow(x[i] - x_mean, 2.0);
        }

        return Math.sqrt(sum_variation / (x.length - 1));
    }

    public static double getMinInGivenDoubleRange(double[][] range){
        double[] minDoubleCandidates = new double[range.length];
        for (int i = 0; i < range.length; i++){
            minDoubleCandidates[i] = getMinInDoubleArray(range[i]);
        }
        return getMinInDoubleArray(minDoubleCandidates);
    }

    public static double getMinInDoubleArray(double[] x){
        double minDouble = Double.POSITIVE_INFINITY;
        for (int i = 0; i < x.length; i++){
            if (minDouble > x[i])
                minDouble = x[i];
        }
        return minDouble;
    }

    public static double getMaxInGivenDoubleRange(double[][] range){
        double[] maxDoubleCandidates = new double[range.length];
        for (int i = 0; i < range.length; i++){
            maxDoubleCandidates[i] = getMaxInDoubleArray(range[i]);
        }
        return getMaxInDoubleArray(maxDoubleCandidates);
    }

    public static double getMaxInDoubleArray(double[] x){
        double maxDouble = Double.NEGATIVE_INFINITY;
        for (int i = 0; i < x.length; i++){
            if (maxDouble < x[i])
                maxDouble = x[i];
        }
        return maxDouble;
    }
}
