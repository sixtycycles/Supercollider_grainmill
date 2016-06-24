//globes
var buf,seconds,bufnum;

var window = Window.new("Select Buffer").front;
var menu = PopUpMenu(window,Rect(180, 10, 150, 20)).background_(Color.red).stringColor_(Color.gray);


var dialog = Button(window,Rect(10, 10, 150, 20));
dialog.states = [["Load Samples", Color.red]];
dialog.action = {
	Dialog.openPanel({|paths|
		var size = paths.size.postln;
		paths.collect{|file|
			a = SoundFile.new;
			a.openRead(file);
			buf= Buffer.alloc(Server.default, a.numFrames, a.numChannels,{| buf | buf.readMsg(a.path)});
			menu.items = paths.collect {|i| i.basename;};
		}
	},multipleSelection:true;);

	menu.action = {|f|
			bufnum = f.value;
		Pdef(\a).set(\bufnum,bufnum);
	};
};
//pattern def default
Pdef(\a,Pbind(*[
	instrument:\sine,
	dur: Pseg((0.05,0.055..0.5),0.1,'step',inf),
	legato: Pseq([5],inf),
	rate: 1,
	startPos: Pseg((0.000001,0.000002..1.0),0.0005,'exp',inf),
		out: 0,
	\amp:0.5
	])
);





Pdef(\a).play;

Pdef(\a).stop;

Pdef(\a).set(\dur,005);

//synth. more to come
SynthDef("sine", {
		|out, bufnum = 0, rate = 1, startPos = 0, sustain = 1, loop = 1, amp = 0.25,lag = 1, pan = 0.0 |
		var audio, env;

		rate = rate * BufRateScale.kr(bufnum);
		startPos = startPos * BufFrames.kr(bufnum);
		audio = BufRd.ar(2, bufnum,Phasor.ar(0, rate, startPos, BufFrames.ir(bufnum)), loop, 4);
	env = EnvGen.ar(Env.sine, 1, timeScale: sustain, doneAction: 2);

		OffsetOut.ar(out,Pan2.ar(audio*env,pan,amp));
	}).store;
