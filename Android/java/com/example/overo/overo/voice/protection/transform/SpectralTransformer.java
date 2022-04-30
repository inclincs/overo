package com.example.overo.overo.voice.protection.transform;

import com.example.overo.audio.util.MathUtil;
import com.example.overo.audio.util.VoiceConstants;
import com.example.overo.audio.util.VoiceUtil;
import com.example.overo.audio.world.World;
import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;

import org.apache.commons.math3.analysis.interpolation.LinearInterpolator;
import org.apache.commons.math3.analysis.polynomials.PolynomialSplineFunction;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.IntStream;

public class SpectralTransformer {

    public static class Result {
        double[][] transformedSpectra;
        VoiceTransformParameter.Spectrum[] spectrumParameters;
    }

    String mode;
    int samplingRate;
    double[][] upperSlopeVarianceRange;
    double[][] lowerSlopeVarianceRange;
    int numberOfMelLinearSections;
    private List<VoiceTransformParameter.Spectrum> spectrum;

    public SpectralTransformer(String mode,
                               int samplingRate,
                               double[][] upperSlopeVarianceRange,
                               double[][] lowerSlopeVarianceRange,
                               int numberOfMelLinearSections) {
        this.mode = mode;
        this.samplingRate = samplingRate;
        this.upperSlopeVarianceRange = upperSlopeVarianceRange;
        this.lowerSlopeVarianceRange = lowerSlopeVarianceRange;
        this.numberOfMelLinearSections = numberOfMelLinearSections;
    }

    public Result convert(double[] f0, double[][] sp) {
        if (mode.equals("constant")) {
            return convert_with_constant_params(sp);
        }
        else if (mode.equals("dynamic")) {
            return convert_with_dynamic_params(f0, sp);
        }
        else {
            return null;
        }
    }

    public Result convert_with_constant_params(double[][] sp) {
        int rfftSize = new World().getSuitableRealFFTSizeForCheaptrick(samplingRate);
        double[][] log_sp = getLogSpectrograms(sp, rfftSize);

        double[] inflectionFrequencies = getInflectionFrequencies();
        double[] warpingSlopes = getWarpingSlopes();

        double[][] sourceAndTargetFrequencies = convertWarpingSlopesToFrequencies(inflectionFrequencies, warpingSlopes);

        double[] sourceFrequencies = sourceAndTargetFrequencies[0];
        double[] targetFrequencies = sourceAndTargetFrequencies[1];

        addSpectralParameter(0, sp.length, warpingSlopes);

        double[][] sourceFrequenciesForFrames = new double[log_sp.length][numberOfMelLinearSections];
        double[][] targetFrequenciesForFrames = new double[log_sp.length][numberOfMelLinearSections];

        for (int i = 0; i < log_sp.length; i++){
            sourceFrequenciesForFrames[i] = sourceFrequencies;
            targetFrequenciesForFrames[i] = targetFrequencies;
        }

        double[][] cv_log_sp = warpFrequencyAxis(log_sp, sourceFrequenciesForFrames, targetFrequenciesForFrames);
        double[][] cv_sp = getExponentialSpectrograms(cv_log_sp, rfftSize);

        Result result = new Result();
        result.transformedSpectra = cv_sp;
        result.spectrumParameters = spectrum.toArray(new VoiceTransformParameter.Spectrum[0]);

        return result;
    }

    public Result convert_with_dynamic_params(double[] f0, double[][] sp) {
        int rfftSize = new World().getSuitableRealFFTSizeForCheaptrick(samplingRate);
        double[][] log_sp = getLogSpectrograms(sp, rfftSize);

        double[] inflectionFrequencies = getInflectionFrequencies();

        double[] warpingSlopes;
        double[] currentWarpingSlopes = new double[numberOfMelLinearSections];

        double[][] sourceFrequenciesForFrames = new double[log_sp.length][numberOfMelLinearSections];
        double[][] targetFrequenciesForFrames = new double[log_sp.length][numberOfMelLinearSections];

        List<Integer> vadRange = new ArrayList<>();
        List<Boolean> voicedMask = VoiceUtil.getVoicedMask(f0);

        for (int i = 0; i < sp.length; i++){
            if ((i == 0) || (voicedMask.get(i - 1).booleanValue() != voicedMask.get(i).booleanValue())){
                warpingSlopes = getWarpingSlopes();
                double[][] sourceAndTargetFrequencies = convertWarpingSlopesToFrequencies(inflectionFrequencies, warpingSlopes);

                double[] sourceFrequencies = sourceAndTargetFrequencies[0];
                double[] targetFrequencies = sourceAndTargetFrequencies[1];

                sourceFrequenciesForFrames[i] = sourceFrequencies;
                targetFrequenciesForFrames[i] = targetFrequencies;

                vadRange.add(i);

                if (vadRange.size() == 2) {
                    addSpectralParameter(vadRange.get(0), vadRange.get(1), currentWarpingSlopes);
                    vadRange.clear();
                    vadRange.add(i);
                }

                currentWarpingSlopes = warpingSlopes;
            } else {
                sourceFrequenciesForFrames[i] = sourceFrequenciesForFrames[i - 1];
                targetFrequenciesForFrames[i] = targetFrequenciesForFrames[i - 1];

                if ((vadRange.size() == 1) && (i == sp.length - 1)){
                    vadRange.add(i);
                    addSpectralParameter(vadRange.get(0), Integer.MAX_VALUE, currentWarpingSlopes);
                }
            }
        }

        double[][] cv_log_sp = warpFrequencyAxis(log_sp, sourceFrequenciesForFrames, targetFrequenciesForFrames);
        double[][] cv_sp = getExponentialSpectrograms(cv_log_sp, rfftSize);

        Result result = new Result();
        result.transformedSpectra = cv_sp;
        result.spectrumParameters = spectrum.toArray(spectrum.toArray(new VoiceTransformParameter.Spectrum[0]));

        return result;
    }

    private double[][] getLogSpectrograms(double[][] sp, int rfftSize) {
        double[][] log_sp = new double[sp.length][rfftSize];
        for (int i = 0; i < sp.length; i++){
            for (int j = 0; j < rfftSize; j++){
                log_sp[i][j] = Math.log(sp[i][j]) / 2.0;
            }
        }
        return log_sp;
    }

    private double[][] getExponentialSpectrograms(double[][] log_sp, int rfftSize) {
        double[][] exp_sp = new double[log_sp.length][rfftSize];
        for (int i = 0; i < log_sp.length; i++){
            for (int j = 0; j < rfftSize; j++){
                exp_sp[i][j] = Math.exp(2.0 * log_sp[i][j]);
            }
        }
        return exp_sp;
    }

    private void addSpectralParameter(int start_vt_index, int end_vt_index, double[] warpingSlopes) {
        if (spectrum == null)
            spectrum = new ArrayList<>();

        VoiceTransformParameter.Spectrum spectrumElement = new VoiceTransformParameter.Spectrum();
        spectrumElement.startSampleIndex = start_vt_index * (long)(0.005 * samplingRate);
        spectrumElement.endSampleIndex = end_vt_index * (long)(0.005 * samplingRate);
        spectrumElement.warpingSlopes = warpingSlopes;
        spectrum.add(spectrumElement);
    }

    private double[][] warpFrequencyAxis(double[][] log_sp,
                                         double[][] sourceFrequenciesForFrames,
                                         double[][] targetFrequenciesForFrames){
        int rfftSize = new World().getSuitableRealFFTSizeForCheaptrick(samplingRate);

        double end_frequency = samplingRate / 2.0;
        int n_frames = sourceFrequenciesForFrames.length;
        int n_frequencies = sourceFrequenciesForFrames[0].length;

        double[][] sourceFrequecyIndexForFrames = new double[n_frames][n_frequencies];
        double[][] targetFrequecyIndexForFrames = new double[n_frames][n_frequencies];

        for (int i = 0; i < n_frames; i++){
            for (int j = 0; j < n_frequencies; j++){
                sourceFrequecyIndexForFrames[i][j] = (sourceFrequenciesForFrames[i][j] / end_frequency) * rfftSize;
                targetFrequecyIndexForFrames[i][j] = (targetFrequenciesForFrames[i][j] / end_frequency) * rfftSize;
            }
        }

        double[][] warpedSp = new double[n_frames][rfftSize];

        for (int i = 0; i < n_frames; i++){
            double[] omega = IntStream.rangeClosed(1, rfftSize)
                    .mapToDouble(x -> (double)x / rfftSize * Math.PI).toArray();
            double[] omega_warped = IntStream.rangeClosed(1, rfftSize)
                    .mapToDouble(x -> (double)x / rfftSize * Math.PI).toArray();

            double[] sourceFrequenciesInRadian = new double[sourceFrequecyIndexForFrames[i].length + 2];
            double[] targetFrequenciesInRadian = new double[targetFrequecyIndexForFrames[i].length + 2];

            for (int j = 0; j < sourceFrequenciesInRadian.length; j++){
                if (j == 0) {
                    sourceFrequenciesInRadian[j] = (1 / rfftSize) * Math.PI;
                    targetFrequenciesInRadian[j] = (1 / rfftSize) * Math.PI;
                    continue;
                }

                if (j == sourceFrequenciesInRadian.length - 1) {
                    sourceFrequenciesInRadian[j] = Math.PI;
                    targetFrequenciesInRadian[j] = Math.PI;
                    continue;
                }

                sourceFrequenciesInRadian[j] = (sourceFrequecyIndexForFrames[i][j - 1] + 1.0) / rfftSize * Math.PI;
                targetFrequenciesInRadian[j] = (targetFrequecyIndexForFrames[i][j - 1] + 1.0) / rfftSize * Math.PI;
            }

            for (int k = 0; k < sourceFrequenciesInRadian.length - 1; k++){
                double alpha = (targetFrequenciesInRadian[k + 1] - targetFrequenciesInRadian[k]) / (sourceFrequenciesInRadian[k + 1] - sourceFrequenciesInRadian[k]);
                for (int w = 0; w < omega_warped.length; w++){
                    if ((sourceFrequenciesInRadian[k] < omega[w]) && (omega[w] <= sourceFrequenciesInRadian[k + 1])) {
                        omega_warped[w] = targetFrequenciesInRadian[k] + alpha * (omega[w] - sourceFrequenciesInRadian[k]);
                    }
                }
            }

            double[] omega_warped_index = new double[omega_warped.length];
            for (int l = 0; l < omega_warped.length; l++){
                if (omega_warped[l] / Math.PI * rfftSize < 1.0) {
                    omega_warped_index[l] = 1.0;
                    continue;
                }
                omega_warped_index[l] = omega_warped[l] / Math.PI * rfftSize;
            }

            warpedSp[i] = linearInterp(IntStream.rangeClosed(1, rfftSize).mapToDouble(x -> x).toArray(), log_sp[i], omega_warped_index);
        }

        return warpedSp;
    }

    private double[] linearInterp(double[] x, double[] y, double[] xi) {
        LinearInterpolator li = new LinearInterpolator(); // or other interpolator
        PolynomialSplineFunction psf = li.interpolate(x, y);

        double[] yi = new double[xi.length];
        for (int i = 0; i < xi.length; i++) {
            yi[i] = psf.value(xi[i]);
        }
        return yi;
    }

    private double[][] convertWarpingSlopesToFrequencies(double[] inflectionFrequencies, double[] warpingSlopes) {
        double[] sourceSectionFrequencies = new double[numberOfMelLinearSections];
        double[] targetSectionFrequencies = new double[numberOfMelLinearSections];

        int upperSection = 0; int lowerSection = 1;
        int[] sections = {upperSection, lowerSection};

        for (int cur_section: sections) {
            double sectionCentroidFrequency = (inflectionFrequencies[cur_section + 1] + inflectionFrequencies[cur_section]) / 2;

            double sourceSectionFrequency = ((warpingSlopes[cur_section] - 1) * inflectionFrequencies[cur_section] + 2*sectionCentroidFrequency) / (warpingSlopes[cur_section] + 1);
            double targetSectionFrequency = -sourceSectionFrequency + 2*sectionCentroidFrequency;

            sourceSectionFrequencies[cur_section] = sourceSectionFrequency;
            targetSectionFrequencies[cur_section] = targetSectionFrequency;
        }

        double[] subInflectionFrequencies = new double[inflectionFrequencies.length - 2];
        for (int i = 0; i < inflectionFrequencies.length - 2; i++){
            subInflectionFrequencies[i] = inflectionFrequencies[1 + i];
        }

        List<Double> sourceFrequencies = new ArrayList<>();
        List<Double> targetFrequencies = new ArrayList<>();

        for (int i = 0; i < subInflectionFrequencies.length; i++){
            sourceFrequencies.add(subInflectionFrequencies[i]);
            targetFrequencies.add(subInflectionFrequencies[i]);
        }

        for (int i = 0; i < numberOfMelLinearSections; i++){
            sourceFrequencies.add(sourceSectionFrequencies[i]);
            targetFrequencies.add(targetSectionFrequencies[i]);
        }

        sourceFrequencies.sort(null);
        targetFrequencies.sort(null);

        double[][] sourceAndTargetFrequencies = new double[2][numberOfMelLinearSections];
        sourceAndTargetFrequencies[0] = sourceFrequencies.stream().mapToDouble(Double::doubleValue).toArray();
        sourceAndTargetFrequencies[1] = targetFrequencies.stream().mapToDouble(Double::doubleValue).toArray();

        return sourceAndTargetFrequencies;
    }

    private double[] getWarpingSlopes() {
        double[] warpingSlopes = new double[numberOfMelLinearSections];

        double prevDeltaSlope = 0.0;

        int upperSection = 0; int lowerSection = 1;
        int[] sections = {upperSection, lowerSection};

        for (int cur_section: sections) {
            double range_min = 0.0;
            double range_max = 0.0;

            if (cur_section == upperSection){
                range_min = MathUtil.getMinInGivenDoubleRange(upperSlopeVarianceRange);
                range_max = MathUtil.getMaxInGivenDoubleRange(upperSlopeVarianceRange);
            }
            if (cur_section == lowerSection){
                int upperSlopeRangeIndex = -1;

                for (int i = 0; i < upperSlopeVarianceRange.length; i++){
                    if ((MathUtil.getMinInDoubleArray(upperSlopeVarianceRange[i]) <= prevDeltaSlope)
                        && (prevDeltaSlope < MathUtil.getMaxInDoubleArray(upperSlopeVarianceRange[i]))){
                        upperSlopeRangeIndex = i;
                        break;
                    }
                }
                range_min = MathUtil.getMinInDoubleArray(lowerSlopeVarianceRange[upperSlopeRangeIndex]);
                range_max = MathUtil.getMaxInDoubleArray(lowerSlopeVarianceRange[upperSlopeRangeIndex]);
            }

            int sign = (Math.random() > 0.5) ? 1 : -1;
            double deltaSlope = range_min + Math.random() * (range_max - range_min);
            prevDeltaSlope = deltaSlope;
            double slope = Math.pow(1 + deltaSlope, sign);

            warpingSlopes[cur_section] = slope;
        }
        return warpingSlopes;
    }

    private double[] getInflectionFrequencies() {
        return new double[]{
                0.0,
                VoiceConstants.INFLECTION_FREQUENCY_PROPORTION * samplingRate / 2.0,
                samplingRate / 2.0
        };
    }

}
