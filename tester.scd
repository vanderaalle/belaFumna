~sourceFile = "/home/andrea/musica/recordings/audioRumentario/bells/chappa1.wav";
~sampleFile = "/home/andrea/musica/recordings/audioRumentario/bells/chappa1.wav";
~rootFreq   = 30.9;  // low B, 6-string bass

(
// ==================
// Bela Fumna
// bass fx pedal — laptop version
// Andrea Valle 2025
// ==================

~sourceFile = "/home/andrea/musica/recordings/audioRumentario/bells/chappa1.wav";
~sampleFile = "/home/andrea/musica/recordings/audioRumentario/bells/chappa1.wav";
~rootFreq   = 30.9;  // low B, 6-string bass

s.waitForBoot({
    Routine({

        ~sourceBuf = Buffer.read(s, ~sourceFile);
        ~sampleBuf = Buffer.read(s, ~sampleFile);

        s.sync;

        // ==================
        // BUSES
        // ==================
        ~dryBus    = Bus.audio(s, 1);
        ~oct1Bus   = Bus.audio(s, 1);
        ~oct2Bus   = Bus.audio(s, 1);
        ~chainBus  = Bus.audio(s, 1);
        ~freezeBus = Bus.audio(s, 1);
        ~sampBus   = Bus.audio(s, 1);
        ~ampBus    = Bus.control(s, 1);
        ~freqBus   = Bus.control(s, 1);

        s.sync;

        // ==================
        // SYNTHDEFS
        // ==================

		SynthDef(\input, { |outBus, ampBus, freqBus, inputGain=1|
    var sig, amp, freq, hasFreq;
    sig = SoundIn.ar(0) * inputGain;

    amp = Amplitude.ar(sig, 0.005, 0.1);

    # freq, hasFreq = Pitch.kr(sig,
        minFreq:  30,
        maxFreq:  500,
        execFreq: 100
    );
    freq = Lag.kr(freq * hasFreq, 0.08);

    Out.ar(outBus, sig);
    Out.kr(ampBus, amp);
    Out.kr(freqBus, freq);
}).add;

SynthDef(\octDown, { |inBus, outBus, wet=0, level=1.8|
    var sig, freq, hasFreq, rm, octDown;
    sig = In.ar(inBus);

    # freq, hasFreq = Pitch.kr(sig, minFreq: 30, maxFreq: 500);
    freq = Lag.kr(freq, 0.08);

    rm      = SinOsc.ar(K2A.ar(freq * 0.5)) * sig;
    octDown = MoogFF.ar(rm, 400, 2.5);
    octDown = octDown * hasFreq;
    octDown = octDown * level;

    Out.ar(outBus, XFade2.ar(sig, octDown, Lag.kr(wet, 0.01) * 2 - 1));
}).add;

SynthDef(\octUp, { |inBus, outBus, wet=0, level=0.8|
    var sig, octUp;
    sig   = In.ar(inBus);
    octUp = PitchShift.ar(
        sig,
        windowSize: 0.2,
        pitchRatio: 2.0,
        pitchDispersion: 0,
        timeDispersion: 0
    );
    octUp = octUp * level;

    Out.ar(outBus, XFade2.ar(sig, octUp, Lag.kr(wet, 0.01) * 2 - 1));
}).add;

SynthDef(\autoWah, { |inBus, outBus, wet=0,
    attackTime=0.001, releaseTime=0.05,
    minFreq=200, maxFreq=3000,
    dbLow= -50, dbHigh= -8,
    gain=3.2, makeupGain=6|
    var sig, amp, db, freq, low, high, filtered;
    sig = In.ar(inBus);

    amp  = Amplitude.ar(sig, attackTime, releaseTime);
    db   = A2K.kr(amp).ampdb.max(-70);

    freq = db.linexp(dbLow, dbHigh, minFreq, maxFreq);
    freq = freq.clip(minFreq, maxFreq);

    low      = LPF.ar(sig, 200);
    high     = HPF.ar(sig, 200);
    filtered = MoogFF.ar(high, freq, gain);
    filtered = (low + filtered) * makeupGain.dbamp;

    Out.ar(outBus, XFade2.ar(sig, filtered, Lag.kr(wet, 0.01) * 2 - 1));
}).add;


        // specFreeze: pitch-navigated buffer + PV_MagFreeze
        SynthDef(\specFreeze, { |inBus, outBus, ampBus, freqBus|
            var sig, inputAmp, freq, bufPos, window, chain, frozen;
            sig      = In.ar(inBus);
            inputAmp = In.kr(ampBus);
            freq     = In.kr(freqBus);

            bufPos = K2A.ar(freq.linlin(30, 500, 0, BufFrames.kr(~sourceBuf) - 1));
            window = BufRd.ar(1, ~sourceBuf, bufPos, interpolation: 4);

            chain  = FFT(LocalBuf(2048), window);
            chain  = PV_MagFreeze(chain, 1);
            frozen = IFFT(chain) * inputAmp;

            Out.ar(outBus, frozen);
        }).add;

        // sampler: onset triggered, pitch-rate, amp-gated
        SynthDef(\sampler, { |inBus, outBus, ampBus, freqBus|
            var sig, inputAmp, freq, rate, trig, player;
            sig      = In.ar(inBus);
            inputAmp = In.kr(ampBus);
            freq     = In.kr(freqBus);

            trig   = Onsets.kr(FFT(LocalBuf(512), sig), 0.5);
            rate   = (freq / ~rootFreq).max(0.1);
            player = PlayBuf.ar(1, ~sampleBuf, rate, trig, loop: 0);
            player = player * inputAmp;

            Out.ar(outBus, player);
        }).add;

        // mixer: K2 crossfades dry vs chain
        // freeze and sampler add on top
        SynthDef(\mixer, { |dryBus, chainBus, freezeBus, sampBus,
            dryWet=0, freezeWet=0, sampWet=0,
            outVol=1|
            var dry, chain, freeze, samp, mix;

            dry    = In.ar(dryBus);
            chain  = In.ar(chainBus);
            freeze = In.ar(freezeBus) * freezeWet;
            samp   = In.ar(sampBus)   * sampWet;

            // K2: 0 = pure dry, 1 = full chain
            mix = XFade2.ar(dry, chain, Lag.kr(dryWet, 0.01) * 2 - 1);

            // freeze and sampler layer on top
            mix = (mix + freeze + samp) * outVol;
            Out.ar(0, mix);
        }).add;

        s.sync;

        // ==================
        // INSTANTIATE
        // ==================
        ~synths = ();
{
        ~synths.input = Synth.head(s, \input, [
            \outBus,    ~dryBus,
            \ampBus,    ~ampBus,
            \freqBus,   ~freqBus,
            \inputGain, 1]);

        ~synths.octDown = Synth.tail(s, \octDown, [
            \inBus,  ~dryBus,
            \outBus, ~oct1Bus,
            \wet, 0]).autogui;

        ~synths.octUp = Synth.tail(s, \octUp, [
            \inBus,  ~oct1Bus,
            \outBus, ~oct2Bus,
            \wet, 0]).autogui;

        ~synths.autoWah = Synth.tail(s, \autoWah, [
            \inBus,  ~oct2Bus,
            \outBus, ~chainBus,
            \wet, 0]).autogui;

        ~synths.specFreeze = Synth.tail(s, \specFreeze, [
            \inBus,   ~dryBus,
            \outBus,  ~freezeBus,
            \ampBus,  ~ampBus,
            \freqBus, ~freqBus]);

        ~synths.sampler = Synth.tail(s, \sampler, [
            \inBus,   ~dryBus,
            \outBus,  ~sampBus,
            \ampBus,  ~ampBus,
            \freqBus, ~freqBus]);

        ~synths.mixer = Synth.tail(s, \mixer, [
            \dryBus,    ~dryBus,
            \chainBus,  ~chainBus,
            \freezeBus, ~freezeBus,
            \sampBus,   ~sampBus,
            \dryWet,    0,
            \freezeWet, 0,
            \sampWet,   0,
            \outVol,    1]);
		}.defer ;

        s.sync;

        // ==================
        // GUI (laptop only)
        // swap for DigitalIn/AnalogIn on Bela
        // ==================
        {
            ~win = Window("Bela Fumna", Rect(100, 100, 340, 460))
                .front.alwaysOnTop_(true);

            ~win.layout = VLayout(
                StaticText().string_("— knobs —").align_(\center),
                HLayout(
                    VLayout(
                        StaticText().string_("K1 input gain"),
                        Knob().action_({ |k|
                            ~synths.input.set(\inputGain,
                                k.value.linlin(0, 1, 0.5, 2.0)) })
                        .value_(0.5)
                    ),
                    VLayout(
                        StaticText().string_("K2 dry/wet"),
                        Knob().action_({ |k|
                            ~synths.mixer.set(\dryWet, k.value) })
                        .value_(0.0)
                    ),
                    VLayout(
                        StaticText().string_("K3 out vol"),
                        Knob().action_({ |k|
                            ~synths.mixer.set(\outVol,
                                k.value.linlin(0, 1, 0, 1.5)) })
                        .value_(0.67)
                    )
                ),

                StaticText().string_("— switches —").align_(\center),

                Button()
                    .states_([["SW1  oct down  OFF", Color.black, Color.gray(0.8)],
                              ["SW1  oct down  ON",  Color.white, Color.blue]])
                    .action_({ |b|
                        ~synths.octDown.set(\wet, b.value) }),

                Button()
                    .states_([["SW2  oct up  OFF",   Color.black, Color.gray(0.8)],
                              ["SW2  oct up  ON",    Color.white, Color.blue]])
                    .action_({ |b|
                        ~synths.octUp.set(\wet, b.value) }),

                Button()
                    .states_([["SW3  autowah  OFF",  Color.black, Color.gray(0.8)],
                              ["SW3  autowah  ON",   Color.white, Color.blue]])
                    .action_({ |b|
                        ~synths.autoWah.set(\wet, b.value) }),

                Button()
                    .states_([["SW4  freeze  OFF",   Color.black, Color.gray(0.8)],
                              ["SW4  freeze  ON",    Color.white, Color.cyan]])
                    .action_({ |b|
                        ~synths.mixer.set(\freezeWet, b.value) }),

                Button()
                    .states_([["SW5  sampler  OFF",  Color.black, Color.gray(0.8)],
                              ["SW5  sampler  ON",   Color.white, Color.cyan]])
                    .action_({ |b|
                        ~synths.mixer.set(\sampWet, b.value) }),

                Button()
                    .states_([["SW6  spare",         Color.black, Color.gray(0.8)],
                              ["SW6  spare  ON",     Color.white, Color.green]])
                    .action_({ |b|
                        // SW6 spare — assign later
                    })
            );
        }.defer;

        "Bela Fumna ready.".postln;

    }).play;
});
)

// cleanup:
// ~synths.do(_.free); ~win.close;