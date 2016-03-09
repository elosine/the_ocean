(
s.options.memSize = 81920;
s.waitForBoot{
	fork{
		// VARIABLES ///////////////////
		var numpl = 2;
		var proc = NetAddr("127.0.0.1", 12321);
		var procfx = NetAddr("127.0.0.1", 12322);
		var g0 = Group.new(s);
		var g0b = Group.after(g0);
		var g1 = Group.after(g0b);
		var g2 = Group.after(g1);
		//Score Index/Cursor
		var scoreixbuf = Buffer.alloc(s, s.sampleRate*16);
		var scoreixAbus = Bus.audio(s);
		var scoreixKbus = Bus.control(s);
		//Loop Index/Cursor
		var loopixbuf = Buffer.alloc(s, s.sampleRate*16);
		var loopixAbus = Bus.audio(s);
		var loopixKbus = Bus.control(s);
		//Sample Buffer
		var liveprocbuf = Buffer.alloc(s, s.sampleRate*16);
		var zerobuf = Buffer.alloc(s, s.sampleRate*16);
		//Sample Bus
		var sampbus = Bus.audio(s);
		var scorerunfunc, scrctlwin, scrctlbut;
		//Control Busses
		var kbus = {Bus.control(s, 33)}!20;
		var totalframes = 44100*16;
		var freezebuf = Buffer.alloc(s, s.sampleRate*2); //buffer for freeze effect
		var envbufs = SoundFile.collectIntoBuffers("/Users/jyang/GitHub/superimposition/Superimposition_Final_Score/grainEnv/*");
		var playa = 0;

		//SYNTH DEFS
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
		SynthDef(\bufrec, {
			arg ich=0, idxbus, buf, gate=1;
			var in, idx, env;
			env = EnvGen.ar(Env.asr(releaseTime:0.01, curve:0),gate, doneAction:2);
			idx = In.ar(idxbus);
			in = SoundIn.ar(ich);
			BufWr.ar(in*env, buf, idx);
		}).add;
		//// FXs ////////////////////////////////
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
		SynthDef(\greyhole, {
			arg ibs, obs=0, gate=1, rel=1.7;
			var del=\del.kr(2, 0.03), damp=\damp.kr(0, 0.03), size=\size.kr(1, 0.03),
			diff=\diff.kr(0.707, 0.03), fb=\fb.kr(0.9, 0.03), moddepth=\moddepth.kr(0.1, 0.03), modfreq=\modfreq.kr(2, 0.03);
			var source, sig, env, amp, sig2;
			amp = \amp.kr(0.8, 0.03);
			env = EnvGen.ar(Env.asr(releaseTime:rel), gate, doneAction:2);
			source = In.ar(ibs);
			sig = Greyhole.ar(source, del, damp, size, diff, fb, moddepth, modfreq);
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(obs, [sig, sig2]*env*amp);
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
		//freeze
		SynthDef(\icy_live, {
			arg ibs, obs=0,buf=0, envbuf = -1, pitchshift=1, winsz=0.8, overlaps=40, resettrig=0, startpos=0.0, endpos=1.0, rand=0.1, ratemin=0.4, ratemax=0.000001, indur=2, t_tr=1, rel=1.2, crv = -6, gate=1, amp=1;
			var sig, ix, krate, in, writehead, whenv, durenv, sig2;
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

		OSCdef(\getix, {|msg|
			var pl = msg[1].asInteger;
			scoreixKbus.get({ |val|
				liveprocbuf.get( (val*(44100*16)).round, { |msg| procfx.sendMsg("/ix", pl, val.asFloat, msg.asFloat) });
			});
		}, "/getix");

		OSCdef(\icy, {|msg|
			var gr = msg[1].asInteger;
			var pl = msg[2].asInteger;
			var lbl = msg[3].asSymbol;
			var mode = msg[4].asInteger;
			msg.postln;
			fork{
				switch( mode,
					0, {
						s.sendMsg(\n_set, 10000+gr, \gate, 0);
						//procfx.sendMsg("/slclear");
						fork{2.do{|ix| procfx.sendMsg("/rmsl", ix.asInteger); 0.1.wait;}};
						procfx.sendMsg("/rmvbt", 100);
					},
					1, {



						s.sendMsg( \s_new, \icy_live, 10000+gr, 0, g2.nodeID, \ibs, sampbus.index, \obs, 0, \buf, freezebuf.bufnum,
							\winsz, 0.6, \overlaps, 27, \rand, 0.5, \envbuf, envbufs[3].bufnum,  \indur, 2, \rel, 3, \crv, -3 );
						procfx.sendMsg("/slclear");
						procfx.sendMsg("/mksl2", 0, 50, 260, "amp", 0.0, 1.0, 34);
						procfx.sendMsg("/mksl2", 1, 120, 260, "rate", 0.0, 1.0, 7);
						s.sendMsg(\n_map, 10000+gr, \amp, kbus[gr].index+0);
						s.sendMsg(\n_map, 10000+gr, \rate, kbus[gr].index+1);
						procfx.sendMsg("/mkbt2", 0, 100, 200, 260, 90.0, 70.0, 0, "iceintrig", 23);
						//Presets
						procfx.sendMsg("/slchg", 0, 0.0);
					}
				)//end switch
			}//end fork
		}, "/icy"); //end OSCdef
		OSCdef(\iceintrig, {s.sendMsg(\n_set, 10000, \t_tr, 1)}, "/iceintrig");



		OSCdef(\sl, {|msg|
			var gr = msg[1].asInteger;
			var pl = msg[2].asInteger;
			var lbl = msg[3].asSymbol;
			var val = msg[4].asFloat;
			kbus[gr].setAt(pl, val);
		}, "/sl");

		OSCdef(\amplify, {|msg|
			var gr = msg[1].asInteger;
			var pl = msg[2].asInteger;
			var lbl = msg[3].asSymbol;
			var mode = msg[4].asInteger;
			msg.postln;
			fork{
				switch( mode,
					0, {
						s.sendMsg(\n_set, 7000+gr, \gate, 0);
						//procfx.sendMsg("/slclear");
						fork{1.do{|ix| procfx.sendMsg("/rmsl", ix.asInteger); 0.1.wait;}};
					},
					1, {
						s.sendMsg( \s_new, lbl, 7000+gr, 0, g2.nodeID, \ibs, sampbus.index, \obs, 0);
						procfx.sendMsg("/slclear");
						procfx.sendMsg("/mksl2", 0, 25, 260, "amp", 0.0, 1.0, 34);
						//index+0 0 corresponds to slider created in line above
						s.sendMsg(\n_map, 7000+gr, \amp, kbus[gr].index+0);
						//Presets
						procfx.sendMsg("/slchg", 0, 0.0);
					}
				)//end switch
			}//end fork
		}, "/amplify"); //end OSCdef


		OSCdef(\greyhole, {|msg|
			var gr = msg[1].asInteger;
			var pl = msg[2].asInteger;
			var lbl = msg[3].asSymbol;
			var mode = msg[4].asInteger;
			fork{
				switch( mode,
					0, {
						s.sendMsg(\n_set, 8000+gr, \gate, 0);
						//procfx.sendMsg("/slclear");
						fork{6.do{|ix| procfx.sendMsg("/rmsl", ix.asInteger); 0.1.wait;}};
					},
					1, {
						s.sendMsg( \s_new, lbl, 8000+gr, 0, g2.nodeID, \ibs, sampbus.index);
						procfx.sendMsg("/slclear");
						procfx.sendMsg("/mksl2", 0, 25, 260, "amp", 0.0, 1.0, 34);
						procfx.sendMsg("/mksl2", 1, 85, 260, "delay", 0.1, 9.0, 7);
						procfx.sendMsg("/mksl2", 2, 145, 260, "damp", 0.0, 1.0, 8);
						procfx.sendMsg("/mksl2", 3, 205, 260, "size", 0.5, 5.0, 9);
						procfx.sendMsg("/mksl2", 4, 265, 260, "diff", 0.0, 1.0, 14);
						procfx.sendMsg("/mksl2", 5, 325, 260, "feedback", 0.0, 1.0, 27);
						//index+0 0 corresponds to slider created in line above
						s.sendMsg(\n_map, 8000+gr, \amp, kbus[gr].index+0);
						s.sendMsg(\n_map, 8000+gr, \del, kbus[gr].index+1);
						s.sendMsg(\n_map, 8000+gr, \damp, kbus[gr].index+2);
						s.sendMsg(\n_map, 8000+gr, \size, kbus[gr].index+3);
						s.sendMsg(\n_map, 8000+gr, \diff, kbus[gr].index+4);
						s.sendMsg(\n_map, 8000+gr, \fb, kbus[gr].index+5);
						//Presets
						procfx.sendMsg("/slchg", 0, 0.0);
						procfx.sendMsg("/slchg", 1, 7.339);
						procfx.sendMsg("/slchg", 2, 0.022);
						procfx.sendMsg("/slchg", 3, 4.120);
						procfx.sendMsg("/slchg", 4, 0.631);
						procfx.sendMsg("/slchg", 5, 0.849);
						procfx.sendMsg("/slchg", 6, 0.716);
						procfx.sendMsg("/slchg", 7, 3.244);
					}
				)//end switch
			}//end fork
		}, "/greyhole"); //end OSCdef



		OSCdef(\petals, {|msg|
			var gr = msg[1].asInteger;
			var pl = msg[2].asInteger;
			var lbl = msg[3].asSymbol;
			var mode = msg[4].asInteger;
			msg.postln;
			fork{
				switch( mode,
					0, {
						s.sendMsg(\n_set, 9000+gr, \gate, 0);
						//procfx.sendMsg("/slclear");
						fork{1.do{|ix| procfx.sendMsg("/rmsl", ix.asInteger); 0.1.wait;}};
						procfx.sendMsg("/rmvbt", 100);
					},
					1, {
						s.sendMsg( \s_new, \petalsOfResonance, 9000+gr, 0, g2.nodeID, \ibs, sampbus.index);
						procfx.sendMsg("/slclear");
						procfx.sendMsg("/mksl2", 0, 25, 260, "amp", 0.0, 1.0, 34);
						s.sendMsg(\n_map, 9000+gr, \masteramp, kbus[gr].index+0);
						procfx.sendMsg("/mkbt2", 0, 100, 110, 260, 80.0, 80.0, 1, "petalstrig", 1);
						//Presets
						procfx.sendMsg("/slchg", 0, 0.0);
					}
				)//end switch
			}//end fork
		}, "/petals"); //end OSCdef
		OSCdef(\petalstrig, {|msg| var tr = msg[4].asInteger; msg.postln; s.sendMsg(\n_set, 9000, \trig, tr)}, "/petalstrig");






		//Score IX //////////////////////////
		OSCdef( \getscoreidx,{ scoreixKbus.get({arg val; proc.sendMsg("/scoreix", val)}) }, "/getscoreidx");
		//FX
		OSCdef(\getloopix, {|msg|
			var pl = msg[1].asInteger;
			loopixKbus.get({ |val| procfx.sendMsg("/loopix", pl, val.asFloat) });
		}, "/getloopix");
		OSCdef(\setix, {|msg|
			var pl = msg[1].asInteger;
			var start = msg[2].asFloat;
			var end = msg[3].asFloat;
			s.sendMsg(\n_free, 6000+pl);
			s.sendMsg( \s_new, \indexer, 6000+pl, 0, g0.nodeID, \buf, loopixbuf.bufnum, \spd, 1, \start, start,
				\end, end, \abus, loopixAbus.index, \kbus, loopixKbus.index);
			s.sendMsg( \n_set, 5000+pl, \idxbus, loopixAbus.index);
		}, "/setix");
		OSCdef(\mainix, {|msg|
			var pl = msg[1].asInteger;
			s.sendMsg(\n_free, 6000+pl);
			s.sendMsg( \n_set, 5000+pl, \idxbus, scoreixAbus.index );
		}, "/mainix");


		OSCdef(\player, {|msg|
			var pl = msg[4].asInteger;
			playa = pl;
			s.sendMsg(\n_set, 4000, \ich, pl); //change which mic in
		}, "/player");




		OSCdef(\inpause, {|msg|
			var pl = msg[4].asInteger;
			switch( pl,
				1, { s.sendMsg(\n_set, 4000, \buf, zerobuf.bufnum) },
				0, {s.sendMsg(\n_set, 4000, \buf, liveprocbuf.bufnum) }
			);
		}, "/inpause");







		0.1.wait;
		//Start Index, Record & Play Synths
		s.sendMsg( \s_new, \indexer, 3000, 0, g0.nodeID, \buf, scoreixbuf.bufnum, \spd, 1, \pos, 0.75, \t_tr, 1, \abus, scoreixAbus.index, \kbus, scoreixKbus.index);
		s.sendMsg( \s_new, \bufrec, 4000, 0, g0b.nodeID, \ich, 0, \idxbus, scoreixAbus.index, \buf, liveprocbuf.bufnum );
		s.sendMsg( \s_new, \sampplay, 5000, 0, g1.nodeID, \obs, sampbus.index, \idxbus, scoreixAbus.index, \buf, liveprocbuf.bufnum );

		//Set Up Score Controls
		//Function to run through score numbers to a point in score - system 1 is evens
		scorerunfunc = {|endnum|
			fork{
				proc.sendMsg("/clrall");
				0.1.wait;
				if(endnum.even,{proc.sendMsg("/togcsr", 0);s.sendMsg(\n_set,3000,\t_tr, 1,\pos, 0.75,\spd, 0)},
					{proc.sendMsg("/togcsr", 1); s.sendMsg(\n_set,3000,\t_tr, 1, \pos, 0.75, \spd, 0)});
				0.1.wait;
				endnum.do{|ix|proc.sendMsg("/scrnum", ix);0.2.wait};
		}}; //end fork & scorerunfunc
		scorerunfunc.value(1); //set score to beginning position
		//SCORE CONTROL GUI
		0.5.wait;
		{ scrctlwin = Window.new( "Score Control", bounds:Rect(20,950,200,80) ).layout_(HLayout(
			scrctlbut = Button()
			.states_([ ["Go", Color.black, Color.green],
				["Stop", Color.black, Color.red] ])
			.action_({ |bt| s.sendMsg(\n_set,3000,\spd, bt.value/*0.667*/) })
			.minHeight_(80),
			TextField().action_({|tf|scorerunfunc.value(tf.value.asInteger);scrctlbut.value_(0)})
			.font_(Font("Monaco", 33))
			.minHeight_(80)
		)).front }.defer;



	}
}
)
n = NetAddr("127.0.0.1", 12322);
n.sendMsg("/rmsl", 1);
