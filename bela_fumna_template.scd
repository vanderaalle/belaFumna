// ╔══════════════════════════════════════════════════════════════════╗
// ║  Bela Fumna — monolithic SynthDef template                       ║
// ║                                                                  ║
// ║  Drop-in starting point for reprogramming the pedal.             ║
// ║  Hardware pin mapping matches the physical wiring of the pedal:  ║
// ║                                                                  ║
// ║    AnalogIn  5   K1  input gain    (0.25–2.0 linexp)            ║
// ║    AnalogIn  6   K2  dry/wet blend                               ║
// ║    AnalogIn  7   K3  output volume (0.25–2.0 linexp)            ║
// ║                                                                  ║
// ║    DigitalIn  0  SW1  (active-low: 1 - DigitalIn.kr(...))       ║
// ║    DigitalIn  2  SW2                                             ║
// ║    DigitalIn  4  SW3                                             ║
// ║    DigitalIn  6  SW4                                             ║
// ║    DigitalIn  7  SW5                                             ║
// ║    DigitalIn 10  SW6                                             ║
// ║                                                                  ║
// ║  Architecture: single monolithic SynthDef.                       ║
// ║  All six effects run unconditionally on every audio block;       ║
// ║  each is gated arithmetically by its footswitch state.           ║
// ║  The wet mix is normalised by the active effect count.           ║
// ╚══════════════════════════════════════════════════════════════════╝

s = Server.default;

s.options.numAnalogInChannels  = 8;
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels   = 16;
s.options.blockSize            = 16;
s.options.numInputBusChannels  = 2;
s.options.numOutputBusChannels = 2;

s.waitForBoot({

	SynthDef(\multiFX, {
		var sig;
		var fx1, fx2, fx3, fx4, fx5, fx6;
		var sw1, sw2, sw3, sw4, sw5, sw6;
		var active, wet, out;

		// ── INPUT ─────────────────────────────────────────────────────
		sig = SoundIn.ar(0) * AnalogIn.kr(5).linexp(0, 0.83, 0.25, 2);

		// ── FOOTSWITCHES (active-low latching 3PDT) ───────────────────
		sw1 = 1 - DigitalIn.kr(0);
		sw2 = 1 - DigitalIn.kr(2);
		sw3 = 1 - DigitalIn.kr(4);
		sw4 = 1 - DigitalIn.kr(6);
		sw5 = 1 - DigitalIn.kr(7);
		sw6 = 1 - DigitalIn.kr(10);

		// ── FX SLOTS ──────────────────────────────────────────────────
		// Replace the body of each slot with your DSP.
		// All six compute unconditionally; use sig as your input.
		// Keep each slot to a single output signal (mono).

		// SW1 ──────────────────────────────────────────────────────────
		fx1 = sig;   // ← replace with your DSP

		// SW2 ──────────────────────────────────────────────────────────
		fx2 = sig;

		// SW3 ──────────────────────────────────────────────────────────
		fx3 = sig;

		// SW4 ──────────────────────────────────────────────────────────
		fx4 = sig;

		// SW5 ──────────────────────────────────────────────────────────
		fx5 = sig;

		// SW6 ──────────────────────────────────────────────────────────
		fx6 = sig;

		// ── MIX ───────────────────────────────────────────────────────
		// Wet = sum of active effects, normalised by count.
		// XFade2: blend 0 → dry, 1 → wet.
		active = (sw1 + sw2 + sw3 + sw4 + sw5 + sw6).max(1);
		wet    = (
			(fx1 * sw1) + (fx2 * sw2) + (fx3 * sw3) +
			(fx4 * sw4) + (fx5 * sw5) + (fx6 * sw6)
		) / active;

		out = XFade2.ar(sig, wet,
			AnalogIn.kr(6).linlin(0, 0.83, -1, 1));  // K2 blend

		Out.ar(0, out * AnalogIn.kr(7).linexp(0, 0.83, 0.25, 2));  // K3 output
	}).add;

	s.sync;
	Synth(\multiFX);

});

ServerQuit.add({ 0.exit });
