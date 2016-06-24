//s.boot;
var load,samples,sbs,bufnmb,bufnmbarry;

//buffer chooser/filenames
samples = Window.new("Select Buffer",Rect(800, 460, 200, 60)).front;
f = PopUpMenu(samples,Rect(10,10,180,20));
f.background_(Color.red);

//load dialog
w = Window.new("Samples",Rect(900, 375, 200, 60),false).front;

load = Button(w, Rect(20, 10, 150, 20));
load.states = [["Load Samples", Color.red, Color.black]];
load.action = {
	Dialog.openPanel({|paths|
		a = paths.collect {|dir|
			(dir.postln);
			SoundFile.openRead(dir);
		};
		a.postln;

		b = a.collect { | sf |
			Buffer.alloc(Server.default, sf.numFrames, sf.numChannels,
				{| buf | buf.readMsg(sf.path)});
		};

		//get file size in secconds:
		n = b.collect {|buffr| buffr.numFrames/buffr.sampleRate;};

		paths.do{|i| i.postln; "".postln};
		("Number of Buffers Allocated = "++(b.size.value;)).postln;

		f.items = j = paths.collect {|i|
			i.basename;
		};
	});

	f.action = {|f|

		bufnmbarry = Array.fill((j.size),{|i| i.value; });
		bufnmb = bufnmbarry[f.value];
		Pdef(\a).set(\bufnum, b.at(f.value));
		("Now Playing Buffer containing "++j[bufnmb].value;)
	};
};

//construct envelope chooser:
z = Window.new("Envelope_Type",Rect(700,375,200,60),false).front;

l = ["sine","triangle","welch","linen","perc"];

sbs = PopUpMenu(z,Rect(10,10,180,20));
sbs.items = l;
sbs.background_(Color.white);
sbs.action = {|sbs|
	l.at(sbs.value).postln;
	Pdef(\a).set(\instrument,l.at(sbs.value));
};

c = Conductor.make { |con, grainSize, spread, overlap, timeStretch, rate, loop, db|

	var out;
	out = 0;

	grainSize .sp(0.005,0.0015,1,0,'exp');
	spread .sp(0,0,1,0);
	rate .sp(1,0.25,10);
	overlap .sp(3,1,10);
	timeStretch .sp(1,0.25,50,0,'exp');
	loop .sp(0,0,1,1);
	db .sp(-32,-90,-12,0,'exp');



	//four synths for the envelope types:
	SynthDef("sine", {
		|out, bufnum = 0, rate = 1, startPos = 0, sustain = 1, loop = 1, amp = 1,lag = 1, pan = 0.0 |
		var audio, env;

		rate = rate * BufRateScale.kr(bufnum);
		startPos = startPos * BufFrames.kr(bufnum);
		audio = BufRd.ar(2, bufnum,Phasor.ar(0, rate, Lag.kr(startPos,lag), BufFrames.ir(bufnum)), loop, 4);
		env = EnvGen.ar(Env.sine, 1, timeScale: sustain,levelScale:amp, doneAction: 2);

		OffsetOut.ar(out,Pan2.ar(audio*env,pan));
	}).store;

	SynthDef("triangle", {
		|out, bufnum = 0, rate = 1, startPos = 0, sustain = 1,loop = 1, amp = 1 ,lag = 1,pan = 0.0|
		var audio, env;

		rate = rate * BufRateScale.kr(bufnum);
		startPos = startPos * BufFrames.kr(bufnum);
		audio = BufRd.ar(2, bufnum, Phasor.ar(0, rate, Lag.kr(startPos,lag), BufFrames.ir(bufnum)), loop, 4);
		env = EnvGen.ar(Env.triangle, 1, timeScale: sustain,levelScale:amp, doneAction: 2);

		OffsetOut.ar(out, Pan2.ar(audio*env,pan));
	}).store;

	SynthDef("welch", {
		|out, bufnum = 0, rate = 1, startPos = 0, sustain = 1,loop = 1, amp = 1 ,lag = 1, pan = 0.0|
		var audio, env;

		rate = rate * BufRateScale.kr(bufnum);
		startPos = startPos * BufFrames.kr(bufnum);
		audio = BufRd.ar(2, bufnum, Phasor.ar(0, rate, Lag.kr(startPos,lag), BufFrames.ir(bufnum)), loop, 4);
		env = EnvGen.ar(Env.linen(0.4,0.1,0.5,1,'welch'), 1, timeScale: sustain, levelScale:amp,doneAction: 2);

		OffsetOut.ar(out, Pan2.ar(audio*env,pan));
	}).store;

	SynthDef("linen", {
		|out, bufnum = 0, rate = 1, startPos = 0, sustain = 1, loop = 1, amp = 1 ,lag = 1,pan = 0.0|
		var audio, env;

		rate = rate * BufRateScale.kr(bufnum);
		startPos = startPos * BufFrames.kr(bufnum);
		audio = BufRd.ar(2, bufnum, Phasor.ar(0, rate, Lag.kr(startPos,lag), BufFrames.ir(bufnum)), loop, 4);
		env = EnvGen.ar(Env.linen, 1, timeScale: sustain,levelScale:amp, doneAction: 2);

		OffsetOut.ar(out, Pan2.ar(audio*env,pan));
	}).store;

	SynthDef("perc", {
		|out, bufnum = 0, rate = 1, startPos = 0, sustain = 1, loop = 1, amp = 1 ,lag = 1,pan = 0.0|
		var audio, env;

		rate = rate * BufRateScale.kr(bufnum);
		startPos = startPos * BufFrames.kr(bufnum);
		audio = BufRd.ar(2, bufnum, Phasor.ar(0, rate, Lag.kr(startPos,lag), BufFrames.ir(bufnum)), loop, 4);
		env = EnvGen.ar(Env.perc, 1, timeScale: sustain, levelScale:amp, doneAction: 2);

		OffsetOut.ar(out, Pan2.ar(audio*env,pan));
	}).store;


	Pdef(\a).set(\instrument,"sine").set(\out,0).set(\bufnum,0);

	con.pattern_(Pdef(\a,Pbind(*[
		dur: Pfunc({
			var grn,sprd;
			grn = grainSize.value;
			sprd =spread.value.rand2;
			(grn+(sprd*grn)).value;
		}),
		legato: overlap,
		rate: rate,
		startPos: Pn( Pseg((0.0001,0.0002..1.0),
			Pfunc({
				y = bufnmb.value;
				t = (n[y]*timeStretch)/10000;
				t.value;
			}),
			'lin')
		),
		loop: loop,
		db: db,

		out: out
	]));
	);

	con.name_("Granular Re-Synthesis");
};

c.show("granular re-synthesis by 60hz");