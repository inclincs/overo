package com.example.overo.audio.world;

public class World {

    private double[] f0;
    private double[] timeaxis;
    private double[][] sp;
    private double[][] ap;

    public void analyzeVoice(double[] x, int fs) {
        double[][] f0AndTimeaxis = stonemask(x, fs);
        f0 = f0AndTimeaxis[0];
        timeaxis = f0AndTimeaxis[1];
        sp = cheaptrick(x, f0, timeaxis, fs);
        ap = d4c(x, f0, timeaxis, fs);
    }

    public double[] getSynthesizedWaveform(double[] f0, double[][] sp, double[][] ap, int fs){
        return synthesis(f0, sp, ap, fs);
    }

    public double[] getF0Estimation(){
        return f0;
    }

    public double[][] getSpectrograms(){ return sp; }

    public double[][] getAperiodicity(){ return ap; }

    public int getSuitableRealFFTSizeForCheaptrick(int samplingRate) {
        return (int)(getSuitableFFTSize(samplingRate) / 2 + 1);
    }

    static {
        System.loadLibrary("WORLD");
    }

    private native double[][] stonemask(double[] x, int fs);
    private native double[][] cheaptrick(double[] x, double[] f0, double[] timeaxis, int fs);
    private native double[][] d4c(double[] x, double[] f0, double[] timeaxis, int fs);
    private native int getSuitableFFTSize(int samplingRate);
    private native double[] synthesis(double[] f0, double[][] sp, double[][] ap, int fs);

}
