package clay.system;


// import kha.Sound;
// import kha.audio2.Audio;
import kha.audio2.Buffer;
import kha.arrays.Float32Array;
import clay.resources.AudioResource;
import clay.audio.AudioEffect;
import clay.audio.AudioChannel;
import clay.audio.AudioGroup;
import clay.audio.Sound;
import clay.utils.Mathf;
import clay.utils.Log.*;

@:cppFileCode("#include <kinc/pch.h>\n#include <kinc/threads/mutex.h>\nstatic kinc_mutex_t mutex;")

class Audio extends AudioGroup {


	public static inline function mutexLock() {

	#if cpp
		untyped __cpp__('kinc_mutex_lock(&mutex)');
	#end

	}
	public static inline function mutexUnlock() {

	#if cpp
		untyped __cpp__('kinc_mutex_unlock(&mutex)');
	#end

	}

	public var sampleRate(get, null):Int;
	public var gain(get, null):Float;

	@:noCompletion public var _sampleRate:Int;
	var _gain:Float;
	var _data:Float32Array;


	@:allow(clay.system.App)
	function new() {

		super();
		
		#if cpp
		untyped __cpp__('kinc_mutex_init(&mutex)');
		#end

		_gain = 0;
		_sampleRate = 44100;
		_data = new Float32Array(512);

		kha.audio2.Audio.audioCallback = mix;

	}

	public function play(res:AudioResource, output:AudioGroup = null):Sound {

		var sound = new Sound(res, output);
		sound.play();
		
		return sound;
		
	}

	function mix(samplesbox:kha.internal.IntBox, buffer:Buffer) {

		var samples = samplesbox.value;
		_sampleRate = buffer.samplesPerSecond;

		if (_data.length < samples) {
			_data = new Float32Array(samples);
		}

		for (i in 0...samples) {
			_data[i] = 0;
		}

		if(!_mute) {
			process(_data, samples);
		}

		_gain = 0;
		for (i in 0...samples) {
			buffer.data.set(buffer.writeLocation, Mathf.clamp(_data[i], -1.0, 1.0) * _volume);
			if(_gain < _data[i]) {
				_gain = _data[i]; // TODO: remove this
			}
			buffer.writeLocation += 1;
			if (buffer.writeLocation >= buffer.size) {
				buffer.writeLocation = 0;
			}
		}

	}

	function get_sampleRate():Int {
		
		clay.system.Audio.mutexLock();
		var v = _sampleRate;
		clay.system.Audio.mutexUnlock();

		return v;
		
	}

	function get_gain():Float {
		
		clay.system.Audio.mutexLock();
		var v = _gain;
		clay.system.Audio.mutexUnlock();

		return v;
		
	}


}
