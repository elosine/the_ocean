SerialPort.listDevices;
//4 TRACKS SAME SAMPLE
//1 MAIN CURSOR
//HIGHLIGHT AREAS THAT ARE BEING PROCESSED
(
s.options.memSize = 81920;
s.waitForBoot{
	fork{
		//VARIABLES///////////////////
		var nvox = 4;
		var samp = Buffer.read(s, "/Users/jyang/GitHub/the_ocean/samples/LZ_OceanRiff_Mono.aif" );
		////Audio Busses
		var ab = {Bus.audio(s)}!nvox;
		//SYNTHDEFS
		SynthDef(\indexer, {
			arg buf, spd=1, start=0, end=1, abus=99, kbus, t_tr=0, pos=0;
			var index, indexnorm;
			index = Phasor.ar(t_tr, BufRateScale.kr(buf)*spd, start*BufFrames.kr(buf), end*BufFrames.kr(buf), pos*BufFrames.kr(buf));
			indexnorm = index.linlin(0.0, BufFrames.kr(buf), 0.0, 1.0);
			Out.ar(abus, index);
			Out.kr(kbus, indexnorm);
		}).add;
		SynthDef(\sampplay, {
			arg idxbus, obs=0, buf, gate=1, start=0, end=1;
			var index, samp, env;
			index = In.ar(idxbus);
			env = EnvGen.ar(Env.asr(releaseTime:0.01, curve:0),gate);
			samp = BufRd.ar(1, buf, index);
			Out.ar(obs, samp*env);
		}).add;
	}//end fork
}//end s.waitForBoot
)

~samp = Buffer.read(s, "/Users/jyang/GitHub/the_ocean/samples/LZ_OceanRiff_Mono.aif" );
~samp.numFrames

