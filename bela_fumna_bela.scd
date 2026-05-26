// ╔══════════════════════════════════════════════════════════════════╗
// ║  Bela Fumna — distributed architecture, Bela hardware version    ║
// ║                                                                  ║
// ║  An alternative implementation using separate SynthDefs          ║
// ║  connected by audio buses.  Each effect runs in its own Synth;  ║
// ║  the bfMixer node handles gating and dry/wet blending.           ║
// ║                                                                  ║
// ║  Effect set (different from the deployed monolithic version):    ║
// ║    SW1  oct down       (ring-mod suboctave, pitch-tracked)       ║
// ║    SW2  oct up         (PitchShift ×2)                           ║
// ║    SW3  autowah        (envelope-follower → MoogFF)              ║
// ║    SW4  spectral freeze (PV_MagFreeze, reads DigitalIn directly) ║
// ║    SW5  sampler A      (onset-triggered PlayBuf, pitch-mapped)   ║
// ║    SW6  sampler B      (second sample buffer)                    ║
// ║                                                                  ║
// ║  Wiring (distributed version — D0–D5 contiguous):               ║
// ║    A0  K1 input gain   (0.25–4.0 linexp)                        ║
// ║    A1  K2 dry/wet blend                                          ║
// ║    A2  K3 output gain  (0.25–4.0 linexp)                        ║
// ║    D0  SW1  D1  SW2  D2  SW3  D3  SW4  D4  SW5  D5  SW6        ║
// ║  Note: the deployed monolithic version uses a different          ║
// ║  wiring (D0,D2,D4,D6,D7,D10; A5,A6,A7) — see                  ║
// ║  nickelodeon20260507/_main.scd.                                  ║
// ╚══════════════════════════════════════════════════════════════════╝

s = Server.default;

// Bela hardware mapping
s.options.numAnalogInChannels  = 4;    // must be 2/4/8 — covers 3 pots
s.options.numAnalogOutChannels = 2;    // minimum
s.options.numDigitalChannels   = 8;    // must be multiple of 8 — covers 6 footswitches
s.options.numInputBusChannels  = 6;    // 2 audio + 4 analog
s.options.numOutputBusChannels = 4;    // 2 audio + 2 analog

// Network + performance
s.options.bindAddress = "0.0.0.0";
s.options.maxLogins   = 4;
s.options.blockSize   = 64;
s.options.memSize     = 65536;         // extra memory for FFT buffers + samples

s.waitForBoot {
	Routine {

		// ════════════════════════════════════════════════════════════
		// SYNTHDEFS
		// ════════════════════════════════════════════════════════════

		// Input — reads K1 (A0) for input gain
		SynthDef(\bfInput, { |outBus|
			var gain = AnalogIn.kr(0).linexp(0, 1, 0.25, 4.0);
			var sig  = SoundIn.ar(0) * gain;
			Out.ar(outBus, sig);
		}).add;

		SynthDef(\bfOctDown, { |inBus, outBus|
			var sig = In.ar(inBus);
			var freq, hasFreq, oct;
			# freq, hasFreq = Pitch.kr(sig,
				minFreq:  30,
				maxFreq:  400,
				execFreq: 100);
			oct = sig * SinOsc.ar(freq * 0.5);
			oct = MoogFF.ar(oct, 400, 2.5) * hasFreq;
			Out.ar(outBus, oct);
		}).add;

		SynthDef(\bfOctUp, { |inBus, outBus|
			var sig = In.ar(inBus);
			var oct = PitchShift.ar(sig,
				windowSize:      0.2,
				pitchRatio:      2.0,
				pitchDispersion: 0.0,
				timeDispersion:  0.01);
			Out.ar(outBus, oct);
		}).add;

		SynthDef(\bfAutowah, { |inBus, outBus|
			var sig    = In.ar(inBus);
			var amp    = Amplitude.ar(sig,
				attackTime:  0.005,
				releaseTime: 0.1);
			var db     = amp.ampdb.max(-70);
			var cutoff = db.linexp(-50, -8, 200, 3000);
			var lo     = LPF.ar(sig, 200);
			var hi     = HPF.ar(sig, 200);
			var wah    = MoogFF.ar(hi, cutoff, 3.0);
			Out.ar(outBus, (lo + wah) * 2.0);
		}).add;

		// Freeze reads SW4 (D3) directly inside the SynthDef
		SynthDef(\bfFreezeSpectral, { |inBus, outBus|
			var sig    = In.ar(inBus);
			var freeze = DigitalIn.kr(3);   // D3 = SW4, 0=live 1=frozen
			var buf    = LocalBuf(4096);
			var chain  = FFT(buf, sig);
			chain      = PV_MagFreeze(chain, freeze);
			Out.ar(outBus, IFFT(chain));
		}).add;

		SynthDef(\bfSamplerCue, { |inBus, outBus, bufnum = 0,
			loMidi  = 23,     // low B
			hiMidi  = 65,     // F4
			readDur = 1.0|

			var sig = In.ar(inBus);
			var freq, hasFreq, midi, startPos;
			var onset, play;

			# freq, hasFreq = Pitch.kr(sig,
				minFreq:  30,
				maxFreq:  800,
				execFreq: 100);

			midi     = freq.cpsmidi;
			startPos = midi.linlin(loMidi, hiMidi,
				0,
				BufFrames.kr(bufnum) - (BufSampleRate.kr(bufnum) * readDur));

			onset = Onsets.kr(
				FFT(LocalBuf(512), sig),
				threshold: 0.5,
				odftype:   \rcomplex);

			play = PlayBuf.ar(1, bufnum,
				rate:     1.0,
				trigger:  onset,
				startPos: Latch.kr(startPos, onset),
				loop:     0);

			Out.ar(outBus, play * hasFreq);
		}).add;

		// Mixer — reads all hardware controls internally.
		// Switches are active-low (1 - DigitalIn) on 3PDT latching footswitches.
		// Wet signal normalised by active effect count to prevent level jumps.
		SynthDef(\bfMixer, { |dryBus,
			fx0Bus, fx1Bus, fx2Bus, fx3Bus, fx4Bus, fx5Bus|

			var dry    = In.ar(dryBus);
			var fxSigs = [
				In.ar(fx0Bus), In.ar(fx1Bus), In.ar(fx2Bus),
				In.ar(fx3Bus), In.ar(fx4Bus), In.ar(fx5Bus)
			];

			// D0–D5: latching footswitches, active-low
			var sws = Array.fill(6, { |i| 1 - DigitalIn.kr(i) });

			var blend   = AnalogIn.kr(1);                          // A1 = K2 dry/wet
			var outGain = AnalogIn.kr(2).linexp(0, 1, 0.25, 4.0); // A2 = K3 output gain

			var nActive = sws.sum.max(1);
			var wet     = fxSigs.collect({ |f, i| f * sws[i] }).sum / nActive;
			var sig     = XFade2.ar(dry, wet, blend.linlin(0, 1, -1, 1));

			Out.ar(0, sig * outGain);
		}).add;

		s.sync;   // ── SynthDefs compiled ──────────────────────────────

		// ════════════════════════════════════════════════════════════
		// BUSES
		// ════════════════════════════════════════════════════════════

		~dryBus = Bus.audio(s, 1);
		~fxBus  = Array.fill(6, { Bus.audio(s, 1) });

		// ════════════════════════════════════════════════════════════
		// BUFFERS
		// Edit paths to match project directory on Bela (/root/<project>/).
		// ════════════════════════════════════════════════════════════

		~buf0 = Buffer.readChannel(s,
			"/root/bela_fumna/samples/1.Detti_Ossessivo.wav",
			channels: [0]).normalize;
		~buf1 = Buffer.readChannel(s,
			"/root/bela_fumna/samples/08-a_history_of_bad_men.aiff",
			channels: [0]).normalize;

		s.sync;   // ── buffers loaded ───────────────────────────────────

		// ════════════════════════════════════════════════════════════
		// INSTANTIATION
		// Node order: bfInput (head) → fx[0..5] → bfMixer (tail)
		// ════════════════════════════════════════════════════════════

		~inputSynth = Synth(\bfInput,
			[\outBus, ~dryBus.index],
			addAction: \addToHead);

		~fxSynths = [
			Synth(\bfOctDown,        [\inBus, ~dryBus.index, \outBus, ~fxBus[0].index], addAction: \addToTail),
			Synth(\bfOctUp,          [\inBus, ~dryBus.index, \outBus, ~fxBus[1].index], addAction: \addToTail),
			Synth(\bfAutowah,        [\inBus, ~dryBus.index, \outBus, ~fxBus[2].index], addAction: \addToTail),
			Synth(\bfFreezeSpectral, [\inBus, ~dryBus.index, \outBus, ~fxBus[3].index], addAction: \addToTail),
			Synth(\bfSamplerCue,     [\inBus, ~dryBus.index, \outBus, ~fxBus[4].index, \bufnum, ~buf0.bufnum], addAction: \addToTail),
			Synth(\bfSamplerCue,     [\inBus, ~dryBus.index, \outBus, ~fxBus[5].index, \bufnum, ~buf1.bufnum], addAction: \addToTail),
		];

		~mixer = Synth(\bfMixer, [
			\dryBus, ~dryBus.index,
			\fx0Bus, ~fxBus[0].index,
			\fx1Bus, ~fxBus[1].index,
			\fx2Bus, ~fxBus[2].index,
			\fx3Bus, ~fxBus[3].index,
			\fx4Bus, ~fxBus[4].index,
			\fx5Bus, ~fxBus[5].index,
		], addAction: \addToTail);

		s.sync;

		"════════════════════════════════".postln;
		"Bela Fumna — distributed / Bela mode ready.".postln;
		"  A0 → K1 input gain".postln;
		"  A1 → K2 dry/wet blend".postln;
		"  A2 → K3 output gain".postln;
		"  D0–D5 → SW1–SW6 footswitches (active-low)".postln;
		"════════════════════════════════".postln;

	}.play(AppClock);
};

ServerQuit.add({ 0.exit });
