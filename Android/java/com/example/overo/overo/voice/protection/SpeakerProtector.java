package com.example.overo.overo.voice.protection;

import com.example.overo.overo.voice.protection.transform.VoiceTransformer;
import com.example.overo.overo.audio.Audio;
import com.example.overo.overo.audio.SpeakerProtectedAudio;
import com.example.overo.overo.voice.protection.transform.parameter.VoiceTransformParameter;

public class SpeakerProtector {

    public static class Result {
        public SpeakerProtectedAudio speakerProtectedAudio;
        public VoiceTransformParameter voiceTransformParameter;
    }

    public static Result protect(Audio audio) {
        VoiceTransformer.Result voiceTransformResult = VoiceTransformer.transform(audio.signals, audio.samplingRate);


        SpeakerProtectedAudio speakerProtectedAudio = new SpeakerProtectedAudio(
                audio.name, voiceTransformResult.transformedSignals, audio.samplingRate,
                audio.bitPerSample, audio.channels
        );

        VoiceTransformParameter voiceTransformParameter = new VoiceTransformParameter(
                voiceTransformResult.pitchParameter,
                voiceTransformResult.spectrumParameters
        );


        Result result = new Result();
        result.speakerProtectedAudio = speakerProtectedAudio;
        result.voiceTransformParameter = voiceTransformParameter;

        return result;
    }
}
