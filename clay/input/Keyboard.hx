package clay.input;


import clay.ds.BitVector;
import clay.input.Key;
import clay.utils.Log.*;
import clay.events.KeyEvent;
import clay.system.App;


@:allow(clay.system.InputManager)
@:access(clay.system.App)
class Keyboard extends Input {


	var key_code_pressed:BitVector;
	var key_code_released:BitVector;
	var key_code_down:BitVector;

	var key_event:KeyEvent;
	var dirty:Bool = false;

	var key_bindings:Map<String, Map<Int, Bool>>;
	var binding:Bindings;


	function new(app:App) {
		
		super(app);

		key_bindings = new Map();
		binding = Clay.input.binding;

	}

	override function enable() {

		if(active) {
			return;
		}

		#if use_keyboard_input

		var k = kha.input.Keyboard.get();
		if(k != null) {
			k.notify(onkeypressed, onkeyreleased, ontextinput);
		}

		#end
		
		key_code_pressed = new BitVector(256);
		key_code_released = new BitVector(256);
		key_code_down = new BitVector(256);

		key_event = new KeyEvent();

		super.enable();

	}

	override function disable() {

		if(!active) {
			return;
		}

		#if use_keyboard_input

		var k = kha.input.Keyboard.get();
		if(k != null) {
			k.remove(onkeypressed, onkeyreleased, ontextinput);
		}

		#end

		key_code_pressed = null;
		key_code_released = null;
		key_code_down = null;

		key_event = null;

		super.disable();

	}

	public function pressed(_key:Key):Bool {

		return key_code_pressed.get(_key);

	}

	public function released(_key:Key):Bool {

		return key_code_released.get(_key);

	}

	public function down(_key:Key):Bool {

		return key_code_down.get(_key);

	}

    public function bind(_name:String, _key:Key) {

    	var b = key_bindings.get(_name);
    	if(b == null) {
    		b = new Map<Int, Bool>();
    		key_bindings.set(_name, b);
    	}
    	b.set(_key, true);

    }

    public function unbind(_name:String) {
    	
    	if(key_bindings.exists(_name)) {
    		key_bindings.remove(_name);
    		binding.remove_all(_name);
    	}

    }

    function check_binding(_key:Int, _pressed:Bool) {

    	for (k in key_bindings.keys()) { // todo: using this is broke hashlink build, ftw?
    		if(key_bindings.get(k).exists(_key)) {
		    	binding.input_event.set_key(k, key_event);
			    if(_pressed) {
			    	binding.inputpressed();
			    } else {
					binding.inputreleased();
			    }
			    return;
    		}
    	}

    }

	function reset() {

		#if use_keyboard_input
		
		_verboser("reset");

		if(dirty) {
			key_code_pressed.disable_all();
			key_code_released.disable_all();
			dirty = false;
		}

		#end
	}

	function onkeypressed(_key:Int) {

		_verboser('onkeypressed: $_key');

		dirty = true;

		key_code_pressed.enable(_key);
		key_code_down.enable(_key);

		key_event.set(_key, KeyEvent.KEY_DOWN);

		check_binding(_key, true);

		_app.emitter.emit(KeyEvent.KEY_DOWN, key_event);

	}

	function onkeyreleased(_key:Int) {

		_verboser('onkeyreleased: $_key');

		dirty = true;

		key_code_released.enable(_key);
		key_code_pressed.disable(_key);
		key_code_down.disable(_key);

		key_event.set(_key, KeyEvent.KEY_UP);

		check_binding(_key, false);

		_app.emitter.emit(KeyEvent.KEY_UP, key_event);

	}
	
	function ontextinput(_char:String) {

		_verboser('ontextinput: $_char');

		_app.emitter.emit(KeyEvent.TEXT_INPUT, _char);

	}


}
