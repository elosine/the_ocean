SerialPort.listDevices;
//HOOK UP POTS TO ARGS
//Play with Petals
(
s.options.memSize = 81920;
s.options.numAudioBusChannels = 200;
s.waitForBoot{
	fork{
		var start = true;
		//LEDs
		var led = ArduinoSMS("/dev/tty.wchusbserial1a120", 9600);
		////Arduino Controlers
		var ino = ArduinoSMS("/dev/tty.wchusbserial1a140", 9600);
		//////Continuous Controller Headers
		var hh = ["p0", "p1", "p2", "p3", "p4", "fsr0"];
		////////Mappings
		var ma = [
			/*p0*/[ [0,1023,0.0,1.0],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*p1*/[ [0,1023,0.0,1.0],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*p2*/[ [0,1023,0.0,1.0],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*p3*/[ [0,1023,0.0,1.0],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*p4*/[ [0,1023,0.0,1.0],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*fsr0*/[100,900,0.0, 100.0]
		];
		//////Switch Headers
		var sh = ["b0", "b1", "b2", "b3"];
		////////Switch Actions
		var switchAction = [
			//b0 = Amplify On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg(\s_new, \amplify, 4000, 0, 1002, \ibs, 120, \obs, 0); led.send(0,1) },
				0,{ s.sendMsg(\n_set, 4000, \gate, 0); led.send(0,0) }
			)},
			//b1 = Freeze On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg(\s_new, \icy, 4100, 0, 1002, \ibs, 120, \obs, 0, \buf, 99, \envbuf, 100, \winsz, 0.6, \overlaps, 27, \rand, 0.5,\rel, 0.7, \crv, -3, \rate, 0.02, \amp, 0.6); led.send(1,1) },
				0,{ s.sendMsg(\n_set, 4100, \gate, 0); led.send(1,0) }
			)},
			//b2 = Petals On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg( \s_new, \petalsOfResonance, 4200, 0, 1002, \ibs, 120); led.send(2,1) },
				0,{ s.sendMsg(\n_set, 4200, \gate, 0); led.send(2,0) }
			)},
			/*b3*/{ |vl| switch( vl, 0,{}, 1,{} ) }
		];
		//////Toggle Headers
		var sth = ["bt7", "bt6", "bt5", "bt4"];
		////////Toggle Actions
		var toggleAction = [

			//bt7 = Amplify On/Off
			{ |vl|
				//Start Indexer and Sample Play once at beginning when bt7 is pressed
				if(start,{
					//Start Indexer
					s.sendMsg(\s_new, \indexer, 2000, 0, 1000, \buf, 0, \abus, 100, \kbus, 0);
					//Play Sample
					s.sendMsg(\s_new, \sampplay, 3000, 0, 1001, \idxbus, 100, \buf, 0, \obs, 120);
					start = false;
				});
				switch( vl,
				1,{ s.sendMsg(\s_new, \amplify, 4001, 0, 1002, \ibs, 120, \obs, 0); led.send(0,1) },
				0,{ s.sendMsg(\n_set, 4001, \gate, 0); led.send(0,0) }
			)},

			//bt6 = Freeze On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg(\s_new, \icy, 4101, 0, 1002, \ibs, 120, \obs, 0, \buf, 99, \envbuf, 100, \winsz, 0.6, \overlaps, 27, \rand, 0.5,\rel, 0.7, \crv, -3, \rate, 0.02, \amp, 0.6); led.send(1,1) },
				0,{ s.sendMsg(\n_set, 4101, \gate, 0); led.send(1,0) }
			)},

			//bt5 = Petals On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg( \s_new, \petalsOfResonance, 4201, 0, 1002, \ibs, 120); led.send(2,1) },
				0,{ s.sendMsg(\n_set, 4201, \gate, 0); led.send(2,0)}
			)}

		];
		//////Arduino Action /////////////////////
		ino.action = {
			arg msg;
			var sm = msg.split($:);
			//Continuous Controllers
			hh.do{ |it ix|
				if( it==sm[0], {
					ma[ix].do{|it1 ix1|
						var val = sm[1].asFloat.linlin( ma[ix][ix1][0],ma[ix][ix1][1],ma[ix][ix1][2],ma[ix][ix1][3] );
						s.sendMsg(\c_set, 100+(ix*10)+ix1, val);
					};//end ma[ix].do
				} ); //end if
			}; //end hh.do
			//Switches
			sh.do{ |it ix|
				if( it==sm[0], {
					var val = sm[1].asInteger;
					switchAction[ix].value(val);
				} ) //end if
			}; //end sh.do
			//Toggles
			sth.do{ |it ix|
				if( it==sm[0], {
					var val = sm[1].asInteger;
					toggleAction[ix].value(val);
				} ) //end if
			}; //end sth.do
		}; //end ino.action

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
			env = EnvGen.ar(Env.asr(releaseTime:0.01),gate,doneAction:2);
			src = In.ar(ibs);
			sig = src;
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(obs, [sig, sig2]*env*amp);
		}).add;
		SynthDef(\icy, {
			arg ibs, obs=0,buf=0, envbuf = -1, pitchshift=1, winsz=0.8, overlaps=40,
			resettrig=0, startpos=0.0, endpos=1.0, rand=0.1, ratemin=0.4, ratemax=0.000001,
			indur=2, t_tr=1, rel=0.3, crv = -6, gate=1;
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
		//// Petals Of Resonance
		SynthDef("petalsOfResonance", {
			arg masteramp=0.5, inamp=1.0, ibs=0, obs=0, fund=80, firstPartial=2, bank2MidiOffset=3.25, spread=1.33, ringL1=7.75, ringL2=15.5, inputLen=1, trig=1, gate=1;
			var	pAmp, partialTunedA, partialTunedB, input, output, outArrayA, outArrayA1, outArrayA2, outArray, inenv, ltdOutput, masterEnv, finalOut,
			p1a, p2a, p3a, p4a, p5a, p6a, p7a, p8a, p9a, p10a, p11a, p12a, p13a,
			p1b, p2b, p3b, p4b, p5b, p6b, p7b, p8b, p9b, p10b, p11b, p12b, p13b,
			resA1, resA2, resA3, resA4, resA5, resA6, resA7, resA8, resA9, resA10, resA11, resA12, resA13,
			resB1, resB2, resB3, resB4, resB5, resB6, resB7, resB8, resB9, resB10, resB11, resB12, resB13;
			var outenv, sig2;
			pAmp = -40.dbamp;
			//Two functions to create two sets of partials
			partialTunedA = 	{
				arg partialNum;
				var freq, freqMidi, tuner, freqTunedMidi, freqTuned;
				//firstPartial allows you to start the series at a higher partial than the fund
				//the fund and spread work together (maybe redundantly)
				//to determine the space between each partial
				freq = fund *( firstPartial + (spread*partialNum) );
				freqMidi = freq.cpsmidi;
				//constantly shifting tuner for each partial
				//so the sound is constantly shifting
				tuner = SinOsc.kr(rrand(0.07, 0.013), 0, 0.5);
				freqTunedMidi = freqMidi + tuner;
				freqTuned = freqTunedMidi.midicps;
			};
			partialTunedB = 	{
				arg partialNum;
				var freq, freqMidi, tuner, freqTunedMidi, freqTuned;
				freq = fund *( firstPartial + (spread*partialNum) );
				freqMidi = freq.cpsmidi;
				tuner = SinOsc.kr(rrand(0.07, 0.013), 0, 0.5);
				freqTunedMidi = freqMidi + tuner + bank2MidiOffset;
				freqTuned = freqTunedMidi.midicps;
			};
			p1a= partialTunedA.value(0);
			p2a= partialTunedA.value(1);
			p3a= partialTunedA.value(2);
			p4a= partialTunedA.value(3);
			p5a= partialTunedA.value(4);
			p6a= partialTunedA.value(5);
			p7a= partialTunedA.value(6);
			p8a= partialTunedA.value(7);
			p9a= partialTunedA.value(8);
			p10a= partialTunedA.value(9);
			p11a= partialTunedA.value(10);
			p12a= partialTunedA.value(11);
			p13a= partialTunedA.value(12);
			p1b= partialTunedB.value(0);
			p2b= partialTunedB.value(1);
			p3b= partialTunedB.value(2);
			p4b= partialTunedB.value(3);
			p5b= partialTunedB.value(4);
			p6b= partialTunedB.value(5);
			p7b= partialTunedB.value(6);
			p8b= partialTunedB.value(7);
			p9b= partialTunedB.value(8);
			p10b= partialTunedB.value(9);
			p11b= partialTunedB.value(10);
			p12b= partialTunedB.value(11);
			p13b= partialTunedB.value(12);
			input = In.ar(ibs);
			//inenv = EnvGen.ar( Env.perc(0.02, inputLen, 1.0, -1), t_tr);
			inenv = EnvGen.ar( Env.asr(0.02, 1, 1.0, -1), trig);
			input =  input * inamp * inenv;
			//Form 13 resonators for each bank/spectrum
			resA1 = DynKlank.ar(`[[p1a], nil, [rrand(ringL1, ringL2)]], input);
			resA2 = DynKlank.ar(`[[p2a], nil, [rrand(ringL1, ringL2)]], input);
			resA3 = DynKlank.ar(`[[p3a], nil, [rrand(ringL1, ringL2)]], input);
			resA4 = DynKlank.ar(`[[p4a], nil, [rrand(ringL1, ringL2)]], input);
			resA5 = DynKlank.ar(`[[p5a], nil, [rrand(ringL1, ringL2)]], input);
			resA6 = DynKlank.ar(`[[p6a], nil, [rrand(ringL1, ringL2)]], input);
			resA7 = DynKlank.ar(`[[p7a], nil, [rrand(ringL1, ringL2)]], input);
			resA8 = DynKlank.ar(`[[p8a], nil, [rrand(ringL1, ringL2)]], input);
			resA9 = DynKlank.ar(`[[p9a], nil, [rrand(ringL1, ringL2)]], input);
			resA10 = DynKlank.ar(`[[p10a], nil, [rrand(ringL1, ringL2)]], input);
			resA11 = DynKlank.ar(`[[p11a], nil, [rrand(ringL1, ringL2)]], input);
			resA12 = DynKlank.ar(`[[p12a], nil, [rrand(ringL1, ringL2)]], input);
			resA13 = DynKlank.ar(`[[p13a], nil, [rrand(ringL1, ringL2)]], input);
			resB1 = DynKlank.ar(`[[p1b], nil, [rrand(ringL1, ringL2)]], input);
			resB2 = DynKlank.ar(`[[p2b], nil, [rrand(ringL1, ringL2)]], input);
			resB3 = DynKlank.ar(`[[p3b], nil, [rrand(ringL1, ringL2)]], input);
			resB4 = DynKlank.ar(`[[p4b], nil, [rrand(ringL1, ringL2)]], input);
			resB5 = DynKlank.ar(`[[p5b], nil, [rrand(ringL1, ringL2)]], input);
			resB6 = DynKlank.ar(`[[p6b], nil, [rrand(ringL1, ringL2)]], input);
			resB7 = DynKlank.ar(`[[p7b], nil, [rrand(ringL1, ringL2)]], input);
			resB8 = DynKlank.ar(`[[p8b], nil, [rrand(ringL1, ringL2)]], input);
			resB9 = DynKlank.ar(`[[p9b], nil, [rrand(ringL1, ringL2)]], input);
			resB10 = DynKlank.ar(`[[p10b], nil, [rrand(ringL1, ringL2)]], input);
			resB11 = DynKlank.ar(`[[p11b], nil, [rrand(ringL1, ringL2)]], input);
			resB12 = DynKlank.ar(`[[p12b], nil, [rrand(ringL1, ringL2)]], input);
			resB13 = DynKlank.ar(`[[p13b], nil, [rrand(ringL1, ringL2)]], input);
			//Make an array of resonators and scramble them up
			outArrayA = [ resA1*pAmp, resA2*pAmp, resA3*pAmp, resA4*pAmp, resA5*pAmp, resA6*pAmp, resA7*pAmp, resA8*pAmp, resA9*pAmp, resA10*pAmp,
				resA11*pAmp, resA12*pAmp, resA13*pAmp, resB1*pAmp, resB2*pAmp, resB3*pAmp, resB4*pAmp, resB5*pAmp, resB6*pAmp, resB7*pAmp,
				resB8*pAmp, resB9*pAmp, resB10*pAmp, resB11*pAmp, resB12*pAmp, resB13*pAmp ].scramble;
			//For Stereo or Multichannel
			//outArrayA1 = outArrayA.copyRange(0, (outArrayA.size/2).asInteger);
			//outArrayA2 = outArrayA.copyRange((outArrayA.size/2).asInteger, outArray.size);
			//outArrayA1 = Mix.ar(outArrayA1);
			//outArrayA2 = Mix.ar(outArrayA2);
			//Mixes resonators to a mono channel
			outArrayA = Mix.ar(outArrayA);
			ltdOutput = Limiter.ar(outArrayA, 0.98, 0.01);
			outenv = EnvGen.ar(Env.asr(0.01, 1, 2), gate, doneAction:2);
			sig2 = DelayC.ar(ltdOutput, 0.2, 0.05);
			Out.ar(obs, [ltdOutput, sig2]*masteramp*outenv);
			}, [0.069]
		).add;
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
3000 = Samp Play Synth
4000s = Amplify Synths
4100s = Icy Synths
4200s = Petals Synths

BUSSES
Audio Busses - 100-199
100 = Main Index Audio Bus
120 = Samp Play Bus

Control Busses 0-4095
0 = Main Index Control Bus
100- = Arduino Control Busses
Each fx has 10 available busses 100-109, 110, 119, ...

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

//ARDUINO CONTROL BUSSES
//100=p0
//101=p1

//105=b0

//113=fsr0



//ENVELOPE BUFFERS
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









