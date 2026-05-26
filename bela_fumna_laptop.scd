// ╔══════════════════════════════════════════════════════════════════╗
// ║  Bela Fumna — laptop testing version                             ║
// ║  Motu Ultralite (or any audio interface)                         ║
// ║  All hardware I/O replaced by GUI controls                       ║
// ╚══════════════════════════════════════════════════════════════════╝

// ── Set your interface before booting ───────────────────────────────
// Check available devices with: ServerOptions.devices
// s.options.inDevice_("Motu Ultralite");
// s.options.outDevice_("Motu Ultralite");
s.options.numInputBusChannels  = 2;
s.options.numOutputBusChannels = 2;
s.options.memSize = 65536;   // extra memory for FFT buffers + samples

s.waitForBoot {
	Routine {

		// ════════════════════════════════════════════════════════════
		// SYNTHDEFS
		// Identical DSP to bela_fumna_bela.scd.
		// Differences:
		//   - \bfInput reads SoundIn.ar(0), gain from a control bus
		//   - \bfMixer reads knob/switch control buses (not hardware)
		// ════════════════════════════════════════════════════════════

		SynthDef(\bfInput, { |outBus, gainBus|
			var gain = In.kr(gainBus).linexp(0, 1, 0.25, 4.0);
			var sig  = SoundIn.ar(0) * gain;
			Out.ar(outBus, sig);
		}).add;

		SynthDef(\bfOctDown, { |inBus, outBus|
			var sig            = In.ar(inBus);
			var freq, hasFreq, oct;
			# freq, hasFreq   = Pitch.kr(sig,
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

		SynthDef(\bfFreezeSpectral, { |inBus, outBus, swBus = 0|
			var sig    = In.ar(inBus);
			var freeze = In.kr(swBus);    // 0 = live, 1 = frozen
			var buf    = LocalBuf(4096);
			var chain  = FFT(buf, sig);
			chain      = PV_MagFreeze(chain, freeze);
			Out.ar(outBus, IFFT(chain));
		}).add;


		SynthDef(\bfSamplerCue, { |inBus, outBus, bufnum = 0,
			loMidi  = 23,     // low B
			hiMidi  = 65,     // F4
			readDur = 1.0|    // seconds to read on each trigger

			var sig      = In.ar(inBus);
			var freq, hasFreq, midi, startPos;
			var onset, rate, play;

			# freq, hasFreq = Pitch.kr(sig,
				minFreq:  30,
				maxFreq:  800,
				execFreq: 100);

			midi     = freq.cpsmidi;

			// pitch → start frame (held until next onset)
			startPos = midi.linlin(loMidi, hiMidi,
				0,
				BufFrames.kr(bufnum) - (BufSampleRate.kr(bufnum) * readDur));

			onset = Onsets.kr(
				FFT(LocalBuf(512), sig),
				threshold:  0.5,
				odftype: \rcomplex);

			// on onset: latch current startPos, trigger PlayBuf from there
			play = PlayBuf.ar(1, bufnum,
				rate:      1.0,
				trigger:   onset,
				startPos:  Latch.kr(startPos, onset),
				loop:      0);

			play = play * hasFreq;

			Out.ar(outBus, play);
		}).add;

		// Mixer reads from control buses set by the GUI
		SynthDef(\bfMixer, { |dryBus,
			fx0Bus, fx1Bus, fx2Bus, fx3Bus, fx4Bus, fx5Bus,
			sw0Bus, sw1Bus, sw2Bus, sw3Bus, sw4Bus, sw5Bus,
			blendBus, gainBus|

			var dry    = In.ar(dryBus);
			var fxSigs = [
				In.ar(fx0Bus), In.ar(fx1Bus), In.ar(fx2Bus),
				In.ar(fx3Bus), In.ar(fx4Bus), In.ar(fx5Bus)
			];
			var sws = [
				In.kr(sw0Bus), In.kr(sw1Bus), In.kr(sw2Bus),
				In.kr(sw3Bus), In.kr(sw4Bus), In.kr(sw5Bus)
			];
			var blend   = In.kr(blendBus);
			var outGain = In.kr(gainBus);

			var nActive = sws.sum.max(1);
			var wet     = fxSigs.collect({ |f, i| f * sws[i] }).sum / nActive;
			var sig     = XFade2.ar(dry, wet, blend.linlin(0, 1, -1, 1));

			Out.ar(0, sig * outGain);
		}).add;

		s.sync;   // ── SynthDefs compiled ──────────────────────────────

		// ════════════════════════════════════════════════════════════
		// BUSES
		// ════════════════════════════════════════════════════════════

		~dryBus   = Bus.audio(s, 1);
		~fxBus    = Array.fill(6, { Bus.audio(s, 1) });

		// Control buses — written by GUI, read by Synths
		~gainInBus  = Bus.control(s, 1);   // K1
		~blendBus   = Bus.control(s, 1);   // K2
		~gainOutBus = Bus.control(s, 1);   // K3
		~swBus      = Array.fill(6, { Bus.control(s, 1) });

		// Safe defaults
		~gainInBus.set(0.85);
		~blendBus.set(0.0);    // full dry at startup
		~gainOutBus.set(0.85);
		~swBus.do { |b| b.set(0) };

		// ════════════════════════════════════════════════════════════
		// BUFFERS
		// Edit paths to point to your local sample files.
		// Using Platform.userHomeDir for portability.
		// ════════════════════════════════════════════════════════════

		~buf0 = Buffer.readChannel(s, "/home/andrea/musica/muProj/belaFumna/samples/1.Detti_Ossessivo.wav",channels:1).normalize;
		~buf1 = Buffer.readChannel(s, "/home/andrea/musica/muProj/belaFumna/samples/08-a_history_of_bad_men.aiff", channels:1).normalize;

		s.sync;   // ── buffers loaded ───────────────────────────────────

		// ════════════════════════════════════════════════════════════
		// INSTANTIATION
		// ════════════════════════════════════════════════════════════

		~inputSynth = Synth(\bfInput, [
			\outBus,  ~dryBus.index,
			\gainBus, ~gainInBus.index,
		], addAction: \addToHead);

		~fxSynths = [
			Synth(\bfOctDown,        [\inBus, ~dryBus.index, \outBus, ~fxBus[0].index],                                                              addAction: \addToTail),
			Synth(\bfOctUp,          [\inBus, ~dryBus.index, \outBus, ~fxBus[1].index],                                                              addAction: \addToTail),
			Synth(\bfAutowah,        [\inBus, ~dryBus.index, \outBus, ~fxBus[2].index],                                                              addAction: \addToTail),
			Synth(\bfFreezeSpectral, [
				\inBus,  ~dryBus.index,
				\outBus, ~fxBus[3].index,
				\swBus,  ~swBus[3].index    // slot 4 = SW4
			], addAction: \addToTail),
			Synth(\bfSamplerCue,        [\inBus, ~dryBus.index, \outBus, ~fxBus[4].index, \bufnum, ~buf0.bufnum],                        addAction: \addToTail),
			Synth(\bfSamplerCue,        [\inBus, ~dryBus.index, \outBus, ~fxBus[5].index, \bufnum, ~buf1.bufnum],                        addAction: \addToTail),
		];

		~mixer = Synth(\bfMixer, [
			\dryBus,   ~dryBus.index,
			\fx0Bus,   ~fxBus[0].index,
			\fx1Bus,   ~fxBus[1].index,
			\fx2Bus,   ~fxBus[2].index,
			\fx3Bus,   ~fxBus[3].index,
			\fx4Bus,   ~fxBus[4].index,
			\fx5Bus,   ~fxBus[5].index,
			\sw0Bus,   ~swBus[0].index,
			\sw1Bus,   ~swBus[1].index,
			\sw2Bus,   ~swBus[2].index,
			\sw3Bus,   ~swBus[3].index,
			\sw4Bus,   ~swBus[4].index,
			\sw5Bus,   ~swBus[5].index,
			\blendBus, ~blendBus.index,
			\gainBus,  ~gainOutBus.index,
		], addAction: \addToTail);

		s.sync;   // ── all nodes running ────────────────────────────────

		// ════════════════════════════════════════════════════════════
		// GUI
		// ════════════════════════════════════════════════════════════
		{
			var w = Window("Bela Fumna", Rect(100, 100, 440, 340))
			.front
			.background_(Color.gray(0.15));

			var labelColor  = Color.gray(0.85);
			var knobColor   = Color(0.98, 0.78, 0.46);
			var swOnColor   = Color(0.24, 0.20, 0.53);
			var swOffColor  = Color.gray(0.25);
			var swLabels ;
			// Title
			StaticText(w, Rect(0, 8, 440, 24))
			.string_("BELA FUMNA")
			.align_(\center)
			.font_(Font("sans-serif", 14, true))
			.stringColor_(Color(0.09, 0.37, 0.65));

			// ── Knobs ────────────────────────────────────────────────
			[
				["K1  input gain",  ~gainInBus,  0.85,  { |sl| ~gainInBus.set(sl.value)  }],
				["K2  dry / wet",   ~blendBus,   0.0,  { |sl| ~blendBus.set(sl.value)   }],
				["K3  output",      ~gainOutBus, 0.85,  { |sl| ~gainOutBus.set(sl.value) }],
			].do { |row, i|
				EZSlider(w,
					Rect(10, 40 + (i * 44), 420, 36),
					row[0],
					ControlSpec(0, 1, \lin, 0, row[2]),
					row[3])
				.setColors(
					stringColor: labelColor,
					sliderBackground: knobColor);
			};
			// ── Switches ─────────────────────────────────────────────
			swLabels = ["I  oct dn", "II  oct up", "III  wah",
				"IV  freeze", "V  smp A",  "VI  smp B"];

			StaticText(w, Rect(10, 182, 420, 18))
			.string_("── switches ─────────────────────────────────────")
			.stringColor_(Color.gray(0.4))
			.font_(Font("sans-serif", 9));

			swLabels.do { |label, i|
				Button(w, Rect(10 + (i * 71), 202, 62, 52))
				.states_([
					[label, labelColor,            swOffColor],
					[label, Color.white,           swOnColor ],
				])
				.font_(Font("sans-serif", 9, true))
				.action_({ |b| ~swBus[i].set(b.value) });
			};

			// ── Slot swap helper ─────────────────────────────────────
			StaticText(w, Rect(10, 266, 420, 18))
			.string_("── slot swap (evaluate in post window) ──────────")
			.stringColor_(Color.gray(0.4))
			.font_(Font("sans-serif", 9));

			StaticText(w, Rect(10, 284, 420, 40))
			.string_(
				"~swapSlot.(0, \\bfOctDown)\n" ++
				"~swapSlot.(4, \\bfSampler, [\\bufnum, ~buf0.bufnum, \\rootFreq, 55])")
			.stringColor_(Color.gray(0.55))
			.font_(Font("Monaco", 8));

		}.defer;

		// ── Slot swap utility ────────────────────────────────────────
		~swapSlot = { |slotIndex, newDef, extraArgs = #[]|
			~fxSynths[slotIndex].free;
			~fxSynths[slotIndex] = Synth(newDef,
				[\inBus,  ~dryBus.index,
					\outBus, ~fxBus[slotIndex].index] ++ extraArgs,
				addAction: \addToTail);
			"Slot % → %".format(slotIndex + 1, newDef).postln;
		};

		"════════════════════════════════".postln;
		"Bela Fumna — laptop mode ready.".postln;
		"  Audio in:  SoundIn channel 0".postln;
		"  Audio out: channel 0".postln;
		"════════════════════════════════".postln;

	}.play(AppClock);
};
