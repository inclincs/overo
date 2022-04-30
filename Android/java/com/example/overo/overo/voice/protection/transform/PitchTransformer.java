package com.example.overo.overo.voice.protection.transform;


import com.example.overo.audio.util.MathUtil;
import com.example.overo.audio.util.VoiceUtil;
import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;

import java.util.List;

import static com.example.overo.audio.util.VoiceConstants.GENERALIZED_PITCH_MEAN;
import static com.example.overo.audio.util.VoiceConstants.GENERALIZED_PITCH_STD;

public class PitchTransformer {

    public static class Result {
        public VoiceTransformParameter.Pitch pitchParameter;
        public double[] transformedPitchContour;
    }

    public static Result convert(double[] pitchContour) {
        Result result = new Result();

        VoiceTransformParameter.Pitch pitchParameter = setPitchStatsFromPitchContour(pitchContour);

        result.pitchParameter = pitchParameter;
        result.transformedPitchContour = logarithmNormalizationPitchTransformation(pitchContour, pitchParameter);

        return result;
    }

    private static VoiceTransformParameter.Pitch setPitchStatsFromPitchContour(double[] pitchContour) {
        VoiceTransformParameter.Pitch pitchParameter = new VoiceTransformParameter.Pitch();

        double[] nonZeroPitchContour = VoiceUtil.getVoicedElements(pitchContour);

        pitchParameter.mean = MathUtil.mean(nonZeroPitchContour);
        pitchParameter.std = MathUtil.std(nonZeroPitchContour);

        return pitchParameter;
    }

    private static double[] logarithmNormalizationPitchTransformation(double[] pitchContour, VoiceTransformParameter.Pitch pitchParameter) {
        double[] transformed_pitchContour = new double[pitchContour.length];

        double logPitchMean = Math.log(pitchParameter.mean);
        double logPitchStd = Math.log(pitchParameter.std);
        double logGeneralizedPitchMean = Math.log(GENERALIZED_PITCH_MEAN);
        double logGeneralizedPitchStd = Math.log(GENERALIZED_PITCH_STD);

        List<Integer> voicedSampleIndex = VoiceUtil.getVoicedElementIndex(pitchContour);

        for(int i = 0; i < voicedSampleIndex.size(); i++) {
            int curIndex = voicedSampleIndex.get(i);
            double logPitchContour = Math.log(pitchContour[curIndex]);

            double conditionalStd = (logPitchContour - logPitchMean) / logPitchStd * logGeneralizedPitchStd;

            transformed_pitchContour[curIndex] = Math.exp(logGeneralizedPitchMean + conditionalStd);
        }

        return transformed_pitchContour;
    }
}
