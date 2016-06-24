(
//globes
var buf,seconds,bufnum,envelopeSelect;
//window to hold stuff
var window = Window.new("Select Buffer").front;
//select between soundfiles
var menu = PopUpMenu(window,Rect(180, 10, 150, 20)).background_(Color.red).stringColor_(Color.gray);
//load dialog - updates buffer number to Pdef when menu item selected
var dialog = Button(window,Rect(10, 10, 150, 20));

dialog.states = [["Load Samples", Color.red]];
dialog.action = {
	Dialog.openPanel({|paths|
		paths.collect{|file|
			a = SoundFile.new;
			a.openRead(file);
			buf= Buffer.alloc(Server.default, a.numFrames, a.numChannels,{| buf | buf.readMsg(a.path)});
			menu.items = paths.collect {|i| i.basename;};
		}
	},multipleSelection:true;);

	menu.action = {|f| bufnum = f.value; Pdef(\a).set(\bufnum,bufnum); };
};

envelopeSelect = PopUpMenu(window,Rect(10, 40,150,20)).background_(Color.white);
envelopeSelect.items = ["sine","triangle","welch","linen","perc"];
envelopeSelect.action = {|sbs| Pdef(\a).set(\instrument,sbs.value);};

//synths!
SynthDef("sine", {
		|out, bufnum = 0, rate = 1, startPos = 0, sustain = 1, loop = 1, amp = 0.25,lag = 1, pan = 0.0 |
		var audio, env;

		rate = rate * BufRateScale.kr(bufnum);
		startPos = startPos * BufFrames.kr(bufnum);
		audio = BufRd.ar(2, bufnum,Phasor.ar(0, rate, startPos, BufFrames.ir(bufnum)), loop, 4);
	env = EnvGen.ar(Env.sine, 1, timeScale: sustain, doneAction: 2);

		OffsetOut.ar(out,Pan2.ar(audio*env,pan,amp));
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

)
//pattern def default
Pdef(\a,Pbind(*[
	instrument:\sine,
	dur: Pseg((0.005,0.0055..0.05),0.001,'sin',inf),
	legato: Pseq([2],inf),
	rate: 1,
	startPos: Pseg((0.0001,0.0002..1.0),0.05,'exp',inf),
		out: 0,
	\amp:0.5
	])
);

Pdef(\a).play;

Pdef(\a).stop;