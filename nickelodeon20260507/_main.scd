s = Server.default;

s.options.numAnalogInChannels = 8;
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels = 16;

s.options.blockSize = 16;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

s.options.postln;

s.waitForBoot({

	SynthDef(\multiFX, {
		var sig, octUp, wah, octDwn, reverb, chorus, reverse;
		var swOct, swWah, swOctDwn, swRev, swChorus, swReverse;
		var blend, wet, active, inVol, outVol, out;

		inVol = AnalogIn.kr(5).linexp(0, 0.83, 0.25, 2);
		sig = SoundIn.ar(0)*inVol;

		// digital switches
		// Se i tuoi switch sono active-low, usa: 1 - DigitalIn.kr(...)
		swOct = 1 - DigitalIn.kr(0);
		swWah = 1 - DigitalIn.kr(6);
		swOctDwn = 1 - DigitalIn.kr(4);
		swRev = 1 - DigitalIn.kr(7);
		swChorus = 1 - DigitalIn.kr(2);
		swReverse = 1 - DigitalIn.kr(10);


		blend = AnalogIn.kr(6).linlin(0, 0.83, 0, 1);

		// effect 1: octave up
		octUp = PitchShift.ar(
			sig,
			windowSize: 0.2,
			pitchRatio: 2.0,
			pitchDispersion: 0.0,
			timeDispersion: 0.01
		);

		// effect 2: autowah
		wah = {
			var amp, db, cutoff, lo, hi;
			amp = Amplitude.ar(sig, 0.005, 0.1);
			db = amp.ampdb.max(-70);
			cutoff = db.linexp(-55, -6, 120, 4000);
			lo = LPF.ar(sig, 200);
			hi = HPF.ar(sig, 200);
			lo + (MoogFF.ar(hi, cutoff, 3.0) * 2.0);
		}.value;


		octDwn = {
			var clean, zc, sub, env;
			clean = LPF.ar(sig, 500);
			env = Amplitude.kr(clean, 0.005, 0.1);
			zc = ToggleFF.ar(clean > 0);
			sub = (zc * 2) - 1;
			sub = LeakDC.ar(sub);
			sub = LPF.ar(sub, 120);
			sub = sub * env * 1.7;
		}.value;

		reverb = {
			var input, tank;
			input = HPF.ar(sig, 180) * 0.35;
			tank = Mix([
				CombC.ar(input, 0.12, 0.031, 3.2),
				CombC.ar(input, 0.12, 0.047, 3.6),
				CombC.ar(input, 0.12, 0.063, 4.0)
			]) * 0.25;

			tank = AllpassC.ar(tank, 0.06, 0.019, 1.2);
			tank = AllpassC.ar(tank, 0.06, 0.027, 1.2);

			LPF.ar(tank, 4200);
		}.value;

		chorus = {

			var dry, wet, mod1, mod2, del1, del2;

			dry = sig;


			mod1 = SinOsc.kr(0.18).range(0.004, 0.022);
			mod2 = SinOsc.kr(0.23, pi).range(0.006, 0.025);


			wet = HPF.ar(sig, 180);

			del1 = DelayC.ar(wet, 0.03, mod1);
			del2 = DelayC.ar(wet, 0.03, mod2);

			wet = Mix([
				del1,
				del2,
				del1 * 0.7 + del2 * 0.5
			]) * 0.7;

			(dry * 0.65) + wet;

		}.value;

		reverse = {
			var trig, pos, dur;
			var sweep, env;
			var rev;
			trig = Dust.kr(5);

			pos = TRand.kr(0.05, 0.28, trig);
			dur = TRand.kr(0.12, 0.5, trig);
			sweep = EnvGen.kr(
				Env([pos, 0.002], [dur], \exp),
				trig
			);
			env = EnvGen.kr(
				Env([0, 1, 0], [dur * 0.8, dur * 0.2]),
				trig
			);

			rev = DelayC.ar(sig, 0.35, sweep);
			rev = FreqShift.ar(
				rev,
				LFNoise1.kr(0.4).range(-80, 120)
			);

			rev = rev * env;
			rev = HPF.ar(rev, 120);
			rev = LPF.ar(rev, 3500);
			Limiter.ar(rev * 2.4);
		}.value;

		active = (swOct + swWah + swOctDwn + swRev + swChorus + swReverse).max(1);
		wet = ((octUp * swOct) + (wah * swWah) + (octDwn * swOctDwn) + (reverb * swRev)) + (chorus * swChorus) + (reverse * swReverse) / active;

		// dry/wet
		out = XFade2.ar(sig, wet, blend.linlin(0, 1, -1, 1));
		outVol = AnalogIn.kr(7).linexp(0, 0.83, 0.25, 2);
		Out.ar(0, out*outVol);
	}).add;

	s.sync;

	Synth(\multiFX);

});

ServerQuit.add({ 0.exit });