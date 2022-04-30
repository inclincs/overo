package com.example.overo.overo.voice.protection.transform;

import android.os.SystemClock;
import android.util.Log;

import com.example.overo.audio.world.World;
import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;

import static com.example.overo.audio.util.VoiceConstants.SPECTRAL_TRANSFORM_LOWER_PARAMETER_RANGES;
import static com.example.overo.audio.util.VoiceConstants.SPECTRAL_TRANSFORM_UPPER_PARAMETER_RANGES;

public class VoiceTransformer {

    public static class Result {
        public double[] transformedSignals;
        public VoiceTransformParameter.Pitch pitchParameter;
        public VoiceTransformParameter.Spectrum[] spectrumParameters;
    }

    public static Result transform(double[] signals, long samplingRate) {
        // ANALYSIS OF VOICE
        long startTime = SystemClock.elapsedRealtime();
        World world = new World();
        world.analyzeVoice(signals, (int) samplingRate);
        long endTime = SystemClock.elapsedRealtime();
        long elapsedTime = endTime - startTime;
        double seconds = elapsedTime / 1000.0;
        Log.e("Overo", "Realtime Processing - Analyze: " + seconds);

        // TRANSFORMATION OF VOICE
        PitchTransformer.Result pitchConversionResult = PitchTransformer.convert(world.getF0Estimation());

        SpectralTransformer spectralTransformer = new SpectralTransformer(
                "constant",
                (int) samplingRate,
                SPECTRAL_TRANSFORM_UPPER_PARAMETER_RANGES,
                SPECTRAL_TRANSFORM_LOWER_PARAMETER_RANGES,
                2
        );

        SpectralTransformer.Result spectrumConversionResult = spectralTransformer.convert(
                world.getF0Estimation(),
                world.getSpectrograms()
        );


        // SYNTHESIS OF VOICE
        startTime = SystemClock.elapsedRealtime();
        double[] transformedSignals = world.getSynthesizedWaveform(
                pitchConversionResult.transformedPitchContour,
                spectrumConversionResult.transformedSpectra,
                world.getAperiodicity(),
                (int) samplingRate
        );
        endTime = SystemClock.elapsedRealtime();
        elapsedTime = endTime - startTime;
        seconds = elapsedTime / 1000.0;
        Log.e("Overo", "Realtime Processing - Synthesize: " + seconds);


        Result result = new Result();
        result.transformedSignals = transformedSignals;
        result.pitchParameter = pitchConversionResult.pitchParameter;
        result.spectrumParameters = spectrumConversionResult.spectrumParameters;

        return result;
    }
}
