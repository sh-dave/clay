package clay.audio;


import kha.arrays.Float32Array;
import clay.resources.AudioResource;
import clay.audio.AudioChannel;
import clay.audio.AudioEffect;
import clay.audio.AudioGroup;
import clay.utils.Mathf;
import clay.utils.Log.*;

class Sound extends AudioChannel {


	public var resource(get, set):AudioResource;

	public var pitch(get, set):Float;
	public var time(get, set):Float;
	public var duration(get, never):Float;
	public var position(get, set):Int;
	public var length(get, never):Int;

	public var paused(get, null):Bool;
	public var playing(get, never):Bool;
	public var finished(get, null):Bool;
	public var channels(get, never):Int;

	public var loop(get, set):Bool;

	@:noCompletion public var _added:Bool;

	var _resource:AudioResource;
	var _paused:Bool;
	var _pitch:Float;
	var _position:Int;
	var _positionRaw:Float;
	var _loop:Bool;
	var _finished:Bool;

	var _cache:Float32Array;
	var _outputToPlay:AudioGroup;


	public function new(?resource:AudioResource, output:AudioGroup = null, maxEffects:Int = 8) {

		super(maxEffects);

		_resource = resource;
		_outputToPlay = output != null ? output : Clay.audio;

		_pitch = 1;
		_position = 0;
		_positionRaw = 0;

		_paused = false;
		_loop = false;
		_finished = false;
		_added = false;

		_cache = new Float32Array(512);
		
	}

	override function process(data:Float32Array, bufferSamples:Int) {

		if(_resource == null) {
			return;
		}
	    
		if (_cache.length < bufferSamples) {
			_cache = new Float32Array(bufferSamples);
		}

		if(_finished) {
			_outputToPlay.remove(this);
			_added = false;
			return;
		}

		var soundData = _resource.uncompressedData;
		var bufferIdx = 0;
		var chunkIdx = 0;
		var chunkLen = 0;
		while (bufferIdx < bufferSamples) {

			chunkLen = Math.floor((soundData.length - _position) / _pitch);
			if(chunkLen > (bufferSamples - bufferIdx)) {
				chunkLen = (bufferSamples - bufferIdx);
			}
			
			while (chunkIdx++ < chunkLen) {
				_cache[bufferIdx++] = soundData[_position];
				_positionRaw += _pitch;
				_position = Math.floor(_positionRaw);
			}

			if (!_loop) {
				if (_position >= soundData.length) {
					_finished = true;
				}
				break;
			} else { 
				if (_position >= soundData.length) {
					_position = 0;
					_positionRaw = 0;
				}
			}
			chunkIdx = 0;
		}

		while (bufferIdx < bufferSamples) {
			_cache[bufferIdx++] = 0;
		}

		processEffects(_cache, bufferSamples);

		bufferIdx = 0;
		while(bufferIdx < bufferSamples) {
			data[bufferIdx] += _cache[bufferIdx] * _volume * _l;
			data[bufferIdx+1] += _cache[bufferIdx+1] * _volume * _r;
			bufferIdx +=2;
		}
		
	}

	public function play():Sound {

		clay.system.Audio.mutexLock();

		_finished = false;
		_paused = false;
		_positionRaw = 0;
		_position = 0;

		if(_resource != null) {
			if(_outputToPlay != null) {
				if(!_added) {
					_outputToPlay.add(this);
					_added = true;
				}
			} else {
				log("cant play: there is no output channel for sound");
			}
		} else {
			log("there is no audio _resource to play");
		}

		clay.system.Audio.mutexUnlock();
		
		return this;

	}

	public function stop():Sound {
		
		clay.system.Audio.mutexLock();

		if(_resource != null) {
			if(_outputToPlay != null) {
				if(_added) {
					_outputToPlay.remove(this);
					_added = false;
				}
			} else {
				log("cant stop: there is no output channel for sound");
			}
		} else {
			log("there is no audio _resource, nothing to stop");
		}

		clay.system.Audio.mutexUnlock();

		return this;

	}

	public function pause():Sound {
		
		clay.system.Audio.mutexLock();
		_paused = true;
		clay.system.Audio.mutexUnlock();

		return this;

	}

	public function unpause():Sound {

		clay.system.Audio.mutexLock();
		_paused = false;
		clay.system.Audio.mutexUnlock();
		
		return this;

	}

	public function setOutput(output:AudioGroup):Sound {

		clay.system.Audio.mutexLock();
		if(_outputToPlay != null) {
			if(_added) {
				_outputToPlay.remove(this);
			}
		}
		_outputToPlay = output;
		clay.system.Audio.mutexUnlock();

		return this;
		
	}

	function get_resource():AudioResource {

		clay.system.Audio.mutexLock();
		var v = _resource;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function set_resource(v:AudioResource):AudioResource {

		clay.system.Audio.mutexLock();
		_resource = v;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_paused():Bool {

		clay.system.Audio.mutexLock();
		var v = _paused;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_pitch():Float {

		clay.system.Audio.mutexLock();
		var v = _pitch;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function set_pitch(v:Float):Float {

		clay.system.Audio.mutexLock();
		_pitch = Mathf.clampBottom(v, 0.01); // todo: 0?
		v = _pitch;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_loop():Bool {

		clay.system.Audio.mutexLock();
		var v = _loop;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function set_loop(v:Bool):Bool {

		clay.system.Audio.mutexLock();
		_loop = v;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_time():Float {

		clay.system.Audio.mutexLock();
		// var v = _position / Clay.audio._sampleRate / _getChannels();
		var v = _position / Clay.audio._sampleRate / 2;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function set_time(v:Float):Float { // TODO: implement this

		// clay.system.Audio.mutexLock();
		// _position = Std.int(v * Clay.audio._sampleRate * _getChannels())
		// _positionRaw = _position;
		// clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_finished():Bool { 

		clay.system.Audio.mutexLock();
		// var v = _position >= _getLength();
		var v = _finished;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_playing():Bool { 

		clay.system.Audio.mutexLock();
		var v = _added;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_position():Int {

		clay.system.Audio.mutexLock();
		var v = _position;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function set_position(v:Int):Int {

		clay.system.Audio.mutexLock();
		_position = v;
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_length():Int {

		clay.system.Audio.mutexLock();
		var v = _getLength();
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_channels():Int {

		clay.system.Audio.mutexLock();
		var v = _getChannels();
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function get_duration():Float {

		clay.system.Audio.mutexLock();
		var v = _getDuration();
		clay.system.Audio.mutexUnlock();

		return v;

	}

	function _getChannels():Int {
		
		if(_resource != null) {
			return _resource.channels;
		}

		return 0;

	}

	function _getLength():Int {
		
		if(_resource != null) {
			return _resource.uncompressedData.length;
		}

		return 0;

	}

	function _getDuration():Float {
		
		if(_resource != null) {
			// return _resource.uncompressedData.length / Clay.audio._sampleRate / _resource.channels;
			return _resource.uncompressedData.length / Clay.audio._sampleRate / 2; // kha uses 2 channels by default
		}

		return 0;

	}


}