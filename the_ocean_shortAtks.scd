SerialPort.listDevices;
//FIX POT
//LOOK AT SHORT ATTACKS AND MAKE BETTER
//IMPLEMENT TRILL


//HOT GLUE Pots
//LONGER RELEASE AND MULTIPLE SYNTHS FOR FREEZE also make attack more percussive
//GRANULAR
////SEND EACH EFFECT OUT TO STEREO BUS
////PICK UP AND GRANULATE
////LMG - SAMPLE TRILL
////Greyhole
//HOOK UP POTS TO ARGS - ONEKNOB WORK OUT SETTINGS FOR ALL 4 EFFECTS
////AMPLIFY, STEREOIFY AND CONTROL DELAY
//STEREOIFY OTHER EFFECTS
////ONE SLIDER IS MASTER VOLUME; SETS AN ARRAY WHICH IS REFERED TO WHEN SWITCHING EFFECTS
////FIND KNOBS AT SARC FOR THE SPIN POTS
//ADD ONE BUTTON (AND ONE FSR?) TO SWITCH GRANULAR STATES; WAY TO HAVE TWO VOICES ASSIGNED TO 2 FSRS
//GRANULAR MODE PRUSUMES ALL 4 EFFECTS ON AND THE BUTTON SWITCHES BETWEEN PAIRS OF EFFECTS - defaultMode, (1,2), (3,4), (1,4), (2,3), (2,4), (1,3)
//EXTRA LEDS SO 1 COLOR PER EFFECT IN DEFAULT MODE
//MAKE SEPARATE FSR BOARD ON SEPARATE ARDUINO?
//KEEP MOVING FORWARD WITH PIECE/PERFORMANCE, LEAVE TIME TO PLAY AND PRACTICE
//Play with Petals
(
s.options.memSize = 81920;
s.options.numAudioBusChannels = 200;
s.waitForBoot{
	fork{
		var start = true;
		var petct = 0;
		var icect = 0;
		var ghct = 0;
		var ampon=false;
		var iceon=false;
		var peton=false;
		var ghon=false;
		//LEDs
		var led = ArduinoSMS("/dev/tty.wchusbserial1a140", 9600);
		////Arduino Controlers
		var ino = ArduinoSMS("/dev/tty.wchusbserial1a120", 9600);
		//////Continuous Controller Headers
		var hh = ["p0", "p1", "p2", "p3", "p4", "fsr0"];
		////////Mappings
		var ma = [
			/*p0*/[ [0,1023,0.0,1.5],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*p1*/[ [0,1023,0.0,1.0],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*p2*/[ [0,1023,0.0,1.0],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*p3*/[ [0,1023,0.01,13.1],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*p4*/[ [0,1023,0.05,10.0],[0,1023,0.0,1.0],[0,1023,0.0,1.0] ],
			/*fsr0*/[ [100,900,0.01, 21.0], [100, 900, 0.0, 2.0] ]
		];
		//////Switch Headers
		var sh = ["b0", "b1", "b2", "b3"];
		////////Switch Actions
		var switchAction = [
			//b0 = Amplify On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg(\s_new, \amplify, 4000, 0, 302, \ibs, 120, \obs, 0, \pobs, 150, \pobs2, 160); led.send(0,1); s.sendMsg(\n_map, 4000, \amp, 100); },
				0,{ s.sendMsg(\n_set, 4000, \gate, 0); if(ampon==false,{ led.send(0,0) }) }
			)},
			//b1 = Freeze On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg(\s_new, \icy, 4100+icect, 0, 302, \ibs, 120, \obs, 0, \pobs, 150, \pobs2, 162, \buf, 99, \envbuf, 100, \winsz, 0.6, \overlaps, 27, \rand, 0.5,\rel, 1.3, \crv, -3, \rate, 0.02, \ratemin, 4.0, \indur, 15); led.send(1,1); s.sendMsg(\n_map, 4100+icect, \amp, 100); },
				0,{ s.sendMsg(\n_set, 4100+icect, \gate, 0); if(iceon==false,{led.send(1,0)}); icect=(icect+1)%5}
			)},
			//b2 = Petals On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg( \s_new, \petalsOfResonance, 4200+petct, 0, 302, \ibs, 120, \obs, 0, \pobs, 150, \pobs2, 164 ); led.send(2,1); s.sendMsg(\n_map, 4200+petct, \amp, 100); },
				0,{ s.sendMsg(\n_set, 4200+petct, \gate, 0); if(peton==false,{led.send(2,0)}); petct=(petct+1)%5 }
			)},
			//b3 = Greyhole
			{ |vl| switch( vl,
				1,{s.sendMsg( \s_new, \greyhole, 4300+ghct, 0, 302, \ibs, 120, \obs, 0, \pobs, 150, \del, 0.3, \pobs2, 166); led.send(3,1); s.sendMsg(\n_map, 4300+ghct, \amp, 100); },
				0,{s.sendMsg(\n_set, 4300+ghct, \gate, 0); if(ghon==false,{led.send(3,0)}); ghct=(ghct+1)%5}
			)}
		];
		//////Toggle Headers
		var sth = ["bt7", "bt6", "bt5", "bt4", "bt8", "bt9"];
		////////Toggle Actions
		var toggleAction = [

			//bt7 = Amplify On/Off
			{ |vl|
				//Start Indexer and Sample Play once at beginning when bt7 is pressed
				if(start,{
					//Start Indexer
					s.sendMsg(\s_new, \indexer, 2000, 0, 300, \buf, 0, \abus, 100, \kbus, 0);
					//Play Sample
					s.sendMsg(\s_new, \sampplay, 3000, 0, 301, \idxbus, 100, \buf, 0, \obs, 120);
					start = false;
				});
				switch( vl,
					1,{ s.sendMsg(\s_new, \amplify, 4001, 0, 302, \ibs, 120, \obs, 0, \pobs, 150, \pobs2, 160); led.send(0,1); ampon=true; s.sendMsg(\n_map, 4001, \amp, 100); },
					0,{ s.sendMsg(\n_set, 4001, \gate, 0); led.send(0,0); ampon=false }
			)},

			//bt6 = Freeze On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg(\s_new, \icy, 4199, 0, 302, \ibs, 120, \obs, 0, \pobs, 150, \buf, 99, \envbuf, 100, \winsz, 0.6, \overlaps, 27, \rand, 0.5,\rel, 1.3, \crv, -3, \rate, 0.02, \ratemin, 4.0, \indur, 15, \pobs2, 162);
					led.send(1,1);
					iceon=true;
					s.sendMsg(\n_map, 4199, \amp, 100);
					s.sendMsg(\n_map, 4199, \rate, 120);
				},
				0,{ s.sendMsg(\n_set, 4199, \gate, 0); led.send(1,0);iceon=false }
			)},

			//bt5 = Petals On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg( \s_new, \petalsOfResonance, 4299, 0, 302, \ibs, 120, \obs, 0, \pobs, 150, \firstPartial, 1,  \fund, 70, \bank2MidiOffset, 0.99, \spread, 0.99, \inamp,0.5, \inputLen, 0.5, \pobs2, 164);
					led.send(2,1);
					s.sendMsg(\n_map, 4299, \amp, 100);
					s.sendMsg(\n_map, 4299, \tunerate, 130);
					s.sendMsg(\n_map, 4299, \itrate, 140);
					peton=true
				},
				0,{ s.sendMsg(\n_set, 4299, \gate, 0); led.send(2,0); peton=false}
			)},

			//bt4 = Greyhole On/Off
			{ |vl| switch( vl,
				1,{ s.sendMsg( \s_new, \greyhole, 4399, 0, 302, \ibs, 120, \obs, 0, \pobs, 150, \del, 0.3, \pobs2, 166);
					led.send(3,1);
					ghon=true;
					s.sendMsg(\n_map, 4399, \amp, 100);
					s.sendMsg(\n_map, 4399, \diff, 110);
				},
				0,{ s.sendMsg(\n_set, 4399, \gate, 0); led.send(3,0);ghon=false }
			)},

			//bt8 = Amplify/LongTone On/Off
			{ |vl| switch( vl,
				1,{
					s.sendMsg(\n_set, 4001, \obs, 180);
					s.sendMsg(\n_set, 4199, \obs, 182);
					s.sendMsg(\n_set, 4299, \obs, 184);
					s.sendMsg(\n_set, 4399, \obs, 186);
					led.send(8,0);
				},
				0,{
					s.sendMsg(\n_set, 4001, \obs, 0);
					s.sendMsg(\n_set, 4199, \obs, 0);
					s.sendMsg(\n_set, 4299, \obs, 0);
					s.sendMsg(\n_set, 4399, \obs, 0);
					led.send(8,1);
				}
			)},


			//bt9 = Granular Switch
			{ |vl| switch( vl,
				1,{
					s.sendMsg(\s_new, \shortAttacks, 5000, 0, 303, \ibs,150,\minrateL, 2, \minrateH, 9,  \maxrateL, 15, \maxrateH, 22, \ebf, 108,\mindurL, 0.05, \mindurH, 0.07, \maxdurL, 0.1, \maxdurH, 0.3);
					s.sendMsg(\n_map, 5000, \minrateL, 150, \minrateH, 150,  \maxrateL, 150, \maxrateH, 150, \amp, 151);
					led.send(9,1);
				},
				0,{
					s.sendMsg(\n_free, 5000);
					led.send(9,0);
				}
			)}

		];
		//0.1.wait;
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
		s.sendMsg( \b_alloc, 99, (15*44100) );
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
		s.sendMsg(\g_new, 300, 1, 1);
		10.do{|ix| s.sendMsg(\g_new, 301+ix, 3, 300+ix)};
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
			arg ibs, obs=0, pobs, pobs2, gate=1;
			var src, sig, env, amp, sig2;
			amp = \amp.kr(0.85, 0.03);
			env = EnvGen.ar(Env.asr(releaseTime:0.01),gate,doneAction:2);
			src = In.ar(ibs);
			sig = src;
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(pobs, [sig, sig2]*env*amp); //out to private (stereo) bus
			Out.ar(pobs2, [sig, sig2]*env*amp); //out to private (stereo) bus
			Out.ar(obs, [sig, sig2]*env*amp);
		}).add;
		SynthDef(\icy, {
			arg ibs, obs=0, pobs, pobs2, buf=0, envbuf = -1, pitchshift=1, winsz=0.8, overlaps=40,
			resettrig=0, startpos=0.0, endpos=1.0, rand=0.1, ratemin=0.4, ratemax=0.000001,
			indur=2, t_tr=1, rel=0.3, crv = -6, gate=1, mamp=0.4;
			var sig, ix, krate, in, writehead, whenv, durenv, sig2, amp;
			amp = \amp.kr(0.33, 0.03)*mamp;
			durenv = EnvGen.ar(Env.asr(0.01, 1, rel, curve: crv),gate,doneAction:2);
			writehead = Phasor.ar(0, BufRateScale.kr(buf), 0, BufFrames.kr(buf));
			whenv = EnvGen.ar(Env.linen(0.0, indur, 0.0), t_tr);
			in = BufWr.ar(In.ar(ibs), buf, writehead*whenv);
			krate = \rate.kr(1, 0.05).linlin(0.0, 1.0, ratemax, ratemin );
			ix = Phasor.kr(resettrig, ((1.0/ControlRate.ir)/(BufFrames.kr(buf)/SampleRate.ir))*krate, startpos, endpos);
			sig = Warp1.ar(1, buf, ix, pitchshift, winsz, envbuf, overlaps,rand);
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(pobs, [sig, sig2]*durenv*amp); //out to private (stereo) bus
			Out.ar(pobs2, [sig, sig2]*durenv*amp); //out to private (stereo) bus
			Out.ar(obs, [sig, sig2]*durenv*amp);
		}).add;
		//// Petals Of Resonance
		SynthDef("petalsOfResonance", {
			arg amp=1.0, inamp=1.0, ibs=0, obs=0, pobs, pobs2, fund=80, firstPartial=1, bank2MidiOffset=0.37, spread=1.33, ringL1=7.75, ringL2=15.5, inputLen=0.5, trig=1, gate=1, tunerate=0.07, itrate=10.5, rel=7;
			var	pAmp, partialTunedA, partialTunedB, input, output, outArrayA, outArrayA1, outArrayA2, outArray, inenv, ltdOutput, ltdOutput1, ltdOutput2, masterEnv, finalOut,
			p1a, p2a, p3a, p4a, p5a, p6a, p7a, p8a, p9a, p10a, p11a, p12a, p13a,
			p1b, p2b, p3b, p4b, p5b, p6b, p7b, p8b, p9b, p10b, p11b, p12b, p13b,
			resA1, resA2, resA3, resA4, resA5, resA6, resA7, resA8, resA9, resA10, resA11, resA12, resA13,
			resB1, resB2, resB3, resB4, resB5, resB6, resB7, resB8, resB9, resB10, resB11, resB12, resB13;
			var outenv, sig2, inputcancel, itr;
			pAmp = -10.dbamp;
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
				//tuner = SinOsc.kr(rrand(0.07, 0.013), 0, 0.5);
				tuner = SinOsc.kr(tunerate, 0, 0.5);
				freqTunedMidi = freqMidi + tuner;
				freqTuned = freqTunedMidi.midicps;
			};
			partialTunedB = 	{
				arg partialNum;
				var freq, freqMidi, tuner, freqTunedMidi, freqTuned;
				freq = fund *( firstPartial + (spread*partialNum) );
				freqMidi = freq.cpsmidi;
				//tuner = SinOsc.kr(rrand(0.07, 0.013), 0, 0.5);
				tuner = SinOsc.kr(tunerate+rrand(0.01, 0.013), 0, 0.5);
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
			//inenv = EnvGen.ar( Env.asr(0.02, 1, 1.0, -1), trig);
			itr = Impulse.kr(itrate);
			inenv = EnvGen.ar( Env.perc(0.02, inputLen, 0.1, -1), itr);
			//input =  input * inamp * inenv;
			input =  input * inamp * inenv;
			//inputcancel = input* -1;
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
			outArrayA = [ resA1*pAmp, resA2*pAmp, resA3*pAmp, resA4*pAmp, resA5*pAmp, resA6*pAmp, resA7*pAmp, resA8*pAmp, resA9*pAmp, resA10*pAmp,resA11*pAmp, resA12*pAmp, resA13*pAmp, resB1*pAmp, resB2*pAmp, resB3*pAmp, resB4*pAmp, resB5*pAmp, resB6*pAmp, resB7*pAmp, resB8*pAmp, resB9*pAmp, resB10*pAmp, resB11*pAmp, resB12*pAmp, resB13*pAmp ].scramble;

			//For Stereo or Multichannel
			outArrayA1 = Array.newFrom(outArrayA);
			outArrayA1 = outArrayA1.copyRange(0, (outArrayA1.size/2).asInteger);
			outArrayA2 = Array.newFrom(outArrayA);
			outArrayA2 = outArrayA2.copyRange( (outArrayA2.size/2).asInteger, outArrayA2.size );
			outArrayA1 = Mix.ar(outArrayA1);
			outArrayA2 = Mix.ar(outArrayA2);
			//STEREO
			ltdOutput1 = Limiter.ar( outArrayA1, 0.98, 0.01 );
			ltdOutput2 = Limiter.ar( outArrayA2, 0.98, 0.01 );
			outenv = EnvGen.ar(Env.asr(0.01, 1, rel), gate, doneAction:2);
			Out.ar(pobs, [ltdOutput1,ltdOutput2]*amp*outenv); //out to private (stereo)bus
			Out.ar(pobs2, [ltdOutput1,ltdOutput2]*amp*outenv); //out to private (stereo)bus
			Out.ar(obs, [ltdOutput1,ltdOutput2]*amp*outenv);
			/*
			//MONO
			//Mixes resonators to a mono channel
			outArrayA = Mix.ar(outArrayA);
			ltdOutput = Limiter.ar(outArrayA, 0.98, 0.01);
			outenv = EnvGen.ar(Env.asr(0.01, 1, 2), gate, doneAction:2);
			Out.ar(obs, ltdOutput*amp*outenv);
			*/
			}, [0.069]
		).add;
		SynthDef(\greyhole, {
			arg ibs, obs=0, pobs, pobs2, gate=1, rel=1.7, mamp=0.6;
			var del=\del.kr(2, 0.03), damp=\damp.kr(0, 0.03), size=\size.kr(1, 0.03),
			diff=\diff.kr(0.707, 0.03), fb=\fb.kr(0.9, 0.03), moddepth=\moddepth.kr(0.1, 0.03), modfreq=\modfreq.kr(2, 0.03);
			var source, sig, env, amp, sig2;
			amp = \amp.kr(0.8, 0.03)*mamp;
			env = EnvGen.ar(Env.asr(releaseTime:rel), gate, doneAction:2);
			source = In.ar(ibs);
			sig = Greyhole.ar(source, del, damp, size, diff, fb, moddepth, modfreq);
			sig2 = DelayC.ar(sig, 0.2, 0.05);
			Out.ar(obs, [sig, sig2]*env*amp);
			Out.ar(pobs, [sig, sig2]*env*amp);
			Out.ar(pobs2, [sig, sig2]*env*amp);
		}).add;
		//GRANULATION SYNTH DEFS
		//LANGUAGE MUSICS GRANULIZATION
		////Short Attacks
		SynthDef(\shortAttacks, {
			arg ibs, obs=0, amp=1, pan=0, dcrv=1,
			mindurL=0.02, mindurH=0.04, maxdurL=(1/7), maxdurH=0.5,
			minrateL=1.85, minrateH=4.0, maxrateL=9.0, maxrateH=15.0,
			ebf= -1;
			var sig, env, gtr, mtrig, dur, rcrv;
			var mindur, maxdur, minrate, maxrate;
			rcrv = \rcrv.kr(9, 0.05);
			mtrig = Impulse.kr(maxrateH);
			mindur = TRand.kr(mindurL, mindurH, mtrig);
			maxdur = TRand.kr(maxdurL, maxdurH, mtrig);
			minrate = TRand.kr(minrateL, minrateH, mtrig);
			maxrate = TRand.kr(maxrateL, maxrateH, mtrig);
			dur = pow( TRand.kr( 0.0, 1.0, mtrig), dcrv ).linlin(0.0, 1.0, mindur, maxdur);
			gtr = Impulse.kr( pow( TRand.kr( 0.0, 1.0, mtrig), rcrv ).linlin(0.0, 1.0, minrate, maxrate));
			sig = In.ar(ibs,2);
			sig = GrainIn.ar(2, gtr,dur,sig,pan,ebf);
			Out.ar(obs, sig*amp);
		}).add;
		//Turn On Amplify/LongTone Light
		led.send(8,1);
	}//end fork
}//end s.waitForBoot
)

/*
LEGEND //////////////////
NODES
300-3009 = Groups
300 = Index Group
301 = Ins Group
302 = Fx Group
2000s = Main Index Synth
300 = Samp Play Synth
4000s = Amplify Synths
4100s = Icy Synths
4200s = Petals Synths
4300s = Greyhole
5000s = Granular
5100 = Short Attacks

BUSSES
Audio Busses - 100-199
100 = Main Index Audio Bus
120 = Samp Play Bus
150 = Stereo Busses (pairs) for grainulation
160 = Stereo Busses (pairs) for grainulation
180 = Dummy Stereo Busses for Alternative Out for Fxs
//150,151 = Amplify
//152,153 = Freeze
//154,155 = Petals
//156, 157 = Greyhole

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
s.sendMsg(\s_new, \amplify, 4000, 0, 302, \ibs, 121, \obs, 0);
//kill
s.sendMsg(\n_set, 4000, \gate, 0);

Icy
//Icy1
s.sendMsg(\s_new, \icy, 4100, 0, 302, \ibs, 120, \obs, 0, \buf, 99, \envbuf, 100, \winsz, 0.6, \overlaps, 27, \rand, 0.5,\rel, 3, \crv, -3, \rate, 0.02, \amp, 0.6);
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


arg masteramp=0.5, inamp=1.0, ibs=0, obs=0, pobs, fund=80, firstPartial=1, bank2MidiOffset=0.37, spread=1.33, ringL1=7.75, ringL2=15.5, inputLen=1, trig=1, gate=1;

s.sendMsg(\n_set, 4299, \inamp, 0.3, \firstPartial, 1, \fund, 70, \bank2MidiOffset, 1.3, \spread, 1, \inputLen, 0.1);

s.sendMsg(\n_set, 4299, \inamp, 0.2,\spread, 0.99, \bank2MidiOffset, 0.99 );
s.sendMsg(\n_set, 4299, \inamp, 0.01,\spread, 0.99, \bank2MidiOffset, 0.99 );
s.sendMsg(\n_set, 4299, \itrate, 10.1, \inputLen, 0.5 );

s.queryAllNodes;

arg ibs, obs=0, gate=1, rel=1.7;
var del=\del.kr(2, 0.03), damp=\damp.kr(0, 0.03), size=\size.kr(1, 0.03),
diff=\diff.kr(0.707, 0.03), fb=\fb.kr(0.9, 0.03), moddepth=\moddepth.kr(0.1, 0.03), modfreq=\modfreq.kr(2, 0.03);


s.volume = -60
s.queryAllNodes
s.volume.volume = 0

v = s.volume;
v.volume = -180
v.mute
s.volume.volume = -60


s.sendMsg(\n_set, 4399, \del, 0.3, \size, 1);

s.volume = newVolume

\shortAttacks,
			arg ibs, obs=0, amp=1, pan=0, dcrv=1,
			mindurL=0.02, mindurH=0.04, maxdurL=(1/7), maxdurH=0.5,
			minrateL=1.85, minrateH=4.0, maxrateL=9.0, maxrateH=15.0,
			ebf= -1;
s.sendMsg(\s_new, \shortAttacks, 5000, 0, 303, \ibs,150);
s.sendMsg(\n_set, 5000, \minrateL, 2, \minrateH, 9,  \maxrateL, 13, \maxrateH, 15, \ebf, 109,\mindurL, 0.05, \mindurH, 0.07, \maxdurL, 0.4, \maxdurH, 0.8);


s.sendMsg( \s_new, \greyhole, 4300+ghct, 0, 302, \ibs, 120, \obs, 0, \pobs, 150, \del, 0.3)
s.queryAllNodes
//Use this to make a randomized long short, short...
//Bursts of interesting patterns, bebop type phrasing
(//AND is multiplication OR is addition
{//swing
	var master, t0, e0, s0, t1, e1, s1, i1, ie1;
	master = Phasor.ar(0, (1.0/(44100.0*1.0)) );
	t0 = master>0.01;

	e0=EnvGen.ar(Env.perc(0.01, 0.2, 1,0),t0);
	s0=SinOsc.ar(660);
	t1 = (master>0.25)*(master<0.63);
	ie1=EnvGen.ar(Env.asr(0.01, 1, 0.01, 0),t1);
	i1 = Impulse.ar(6)*ie1;
	e1=EnvGen.ar(Env.perc(0.01, 0.2, 1,0),i1);
	s1=SinOsc.ar(440);
	Out.ar(0, [s1*e1, s0*e0])

}.play
)





