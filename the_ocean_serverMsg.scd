SerialPort.listDevices;
//4 TRACKS SAME SAMPLE
//1 MAIN CURSOR
//HIGHLIGHT AREAS THAT ARE BEING PROCESSED
(
s.options.memSize = 81920;
s.options.numAudioBusChannels = 200;
s.waitForBoot{
	fork{
		var nvox = 4;
		////Main Sample
		s.sendMsg(\b_read, 0, "/Users/jyang/GitHub/the_ocean/samples/LZ_OceanRiff_Mono.aif");
		////Groups
		s.sendMsg(\g_new,
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
			env = EnvGen.ar(Env.asr(releaseTime:0.1),gate,doneAction:2);
			src = In.ar(ibs);
			sig = src;
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(obs, [sig, sig2]*env*amp);
		}).add;
		//OSC DEFS//////////////////////////
		OSCdef(\amplify, {|msg|
			var vox=msg[1].asInteger;

		}, "/amplify");
		0.2.wait;
		//SYNTHS////////////////////////////
		////Main Index Synth
		s.sendMsg(\s_new, \indexer, 2000, 0, 1000, \buf, 0, \abus, 100, \kbus, 0);
		////Play Sample Synths
		nvox.do{|ix| s.sendMsg(\s_new, \sampplay, 3000+ix, 0, 1001, \idxbus, 100, \buf, 0, \obs, 120+ix)};
	}//end fork
}//end s.waitForBoot
)
s.queryAllNodes
/*
LEGEND //////////////////
NODES
1000-1009 = Groups
1000 = Index Group
1001 = Ins Group
1002 = Fx Group
2000s = Main Index Synth
3000s = Samp Play Synths
BUSSES
Audio Busses - 100-199
100 = Main Index Audio Bus
120-130 = Audio Patch Busses
Control Busses 0-4095
0 = Main Index Control Bus
BUFFERS - 1024
0 = Sample 1
*/



