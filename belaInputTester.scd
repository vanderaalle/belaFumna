s = Server.default;

s.options.numAnalogInChannels = 8;
s.options.numAnalogOutChannels = 8;
s.options.numDigitalChannels = 16;

s.options.blockSize = 16;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 2;

s.options.postln;

s.waitForBoot({
	// modulate frequency of a sine oscillator
	(
		SynthDef("help-AnalogIn",{ arg out=0;

			DigitalIn.kr(6).poll;
			DigitalIn.kr(7).poll;
			DigitalIn.kr(10).poll;
			DigitalIn.kr(0).poll;
			DigitalIn.kr(2).poll;
			DigitalIn.kr(4).poll;

			AnalogIn.kr(6).poll;
			AnalogIn.kr(7).poll;
			AnalogIn.kr(5).poll;
		}).send(s);
	);

	s.sync;
	Synth.new("help-AnalogIn", target: s);
});
ServerQuit.add({ 0.exit }); // quit if the button is pressed
