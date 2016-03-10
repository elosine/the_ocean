SerialPort.listDevices;
//Set Up Leds on separate arduino - charlieplex 13leds
//Use Physical Controllers to mod DSP
//Petals
//Decimate
//Filters
//Spectral
(
s.options.memSize = 81920;
s.options.numAudioBusChannels = 200;
s.waitForBoot{
	fork{
		var nvox = 4;
		////Main Sample
		s.sendMsg(\b_allocRead, 0, "/Users/jyang/GitHub/the_ocean/samples/LZ_OceanRiff_Mono.aif");
		////Buffer for Icy Effect
		s.sendMsg( \b_alloc, 99, (3*44100) );
		////Envelope Buffers
		s.sendMsg(\b_allocRead, 100, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_3stageLinear.aif");
		s.sendMsg(\b_allocRead, 101, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_hanning.aif");
		s.sendMsg(\b_allocRead, 102, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_gauss.aif");
		s.sendMsg(\b_allocRead, 103, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_blackman.aif");
		s.sendMsg(\b_allocRead, 104, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_hamming.aif");
		s.sendMsg(\b_allocRead, 105, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_quasiGauss.aif");
		s.sendMsg(\b_allocRead, 106, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_blackmanHarris.aif");
		s.sendMsg(\b_allocRead, 107, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_tri.aif");
		s.sendMsg(\b_allocRead, 108, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_expodec.aif");
		s.sendMsg(\b_allocRead, 109, "/Users/jyang/GitHub/the_ocean/grainEnv/gEnv_rexpodec.aif");
		////Groups
		s.sendMsg(\g_new, 1000, 1, 1);
		10.do{|ix| s.sendMsg(\g_new, 1001+ix, 3, 1000+ix)};
		//SYNTHDEFS///////////////////
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
		SynthDef(\amplify, {
			arg ibs, obs=0, gate=1;
			var src, sig, env, amp, sig2;
			amp = \amp.kr(0.85, 0.03);
			env = EnvGen.ar(Env.asr(releaseTime:0.2),gate,doneAction:2);
			src = In.ar(ibs);
			sig = src;
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(obs, [sig, sig2]*env*amp);
		}).add;
		SynthDef(\icy, {
			arg ibs, obs=0,buf=0, envbuf = -1, pitchshift=1, winsz=0.8, overlaps=40,
			resettrig=0, startpos=0.0, endpos=1.0, rand=0.1, ratemin=0.4, ratemax=0.000001,
			indur=2, t_tr=1, rel=1.2, crv = -6, gate=1;
			var sig, ix, krate, in, writehead, whenv, durenv, sig2, amp;
			amp = \amp.kr(0.5, 0.03);
			durenv = EnvGen.ar(Env.asr(0.01, 1, rel, curve: crv),gate,doneAction:2);
			writehead = Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf));
			whenv = EnvGen.ar(Env.linen(0.0, indur, 0.0), t_tr);
			in = BufWr.ar(In.ar(ibs), buf, writehead*whenv);
			krate = \rate.kr(1, 0.05).linlin(0.0, 1.0, ratemax, ratemin );
			ix = Phasor.kr(resettrig, ((1.0/ControlRate.ir)/(BufFrames.kr(buf)/SampleRate.ir))*krate, startpos, endpos);
			sig = Warp1.ar(1, buf, ix, pitchshift, winsz, envbuf, overlaps,rand);
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(obs, [sig, sig2]*durenv*amp);
		}).add;
		0.2.wait;
		//SYNTHS////////////////////////////
		////Main Index Synth
		s.sendMsg(\s_new, \indexer, 2000, 0, 1000, \buf, 0, \abus, 100, \kbus, 0);
		////Play Sample Synths
		nvox.do{|ix| s.sendMsg(\s_new, \sampplay, 3000+ix, 0, 1001, \idxbus, 100, \buf, 0, \obs, 120+ix)};
	}//end fork
}//end s.waitForBoot
)
/*
LEGEND //////////////////
NODES
1000-1009 = Groups
1000 = Index Group
1001 = Ins Group
1002 = Fx Group
2000s = Main Index Synth
3000s = Samp Play Synths
4000s = Amplify Synths
4100s = Icy Synths

BUSSES
Audio Busses - 100-199
100 = Main Index Audio Bus
120-130 = Audio Patch Busses
Control Busses 0-4095
0 = Main Index Control Bus

BUFFERS - 1024
0 = Sample 1
99 = Freeze Buffer
100-109 = Env Buffers

COMMANDS
FXs
Amplify
s.sendMsg(\s_new, \amplify, 4000, 0, 1002, \ibs, 121, \obs, 0);
//kill
s.sendMsg(\n_set, 4000, \gate, 0);

Icy
//Icy1
s.sendMsg(\s_new, \icy, 4100, 0, 1002, \ibs, 120, \obs, 0, \buf, 99, \envbuf, 100, \winsz, 0.6, \overlaps, 27, \rand, 0.5,\rel, 3, \crv, -3, \rate, 0.02, \amp, 0.6);
//kill
s.sendMsg(\n_set, 4100, \gate, 0);

*/




//100=3StageLinear
//101=Hanning
//102=Gauss
//103=Blackman
//104=Hamming
//105=quasiGauss
//106=BlackmanHarris
//107=tri
//108=expodec
//109=rexpodec









