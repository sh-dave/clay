package clay.events;

#if macro
import haxe.macro.Expr;
#else

@:multiType
abstract Signal<T>(SignalBase<T>){


	public var emit(get, never):T;
	public var handlers(get, never):Array<SignalHandler<T>>;
	public var processing(get, never):Bool;


	public function new();

	public inline function add(listener:T, order:Int = 0) {

		this.add(listener, order);

	}

	public inline function add_once(listener:T, order:Int = 0) {

		this.add_once(listener, order);

	}

	// public inline function queue(listener:T, order:Int = 0) {

	// 	// this.add_once(listener, order);

	// }

	public inline function remove(listener:T) {

		this.remove(listener);

	}
	
	// public inline function dequeue(listener:T) {

	// 	// this.remove(listener);

	// }

	public inline function has(listener:T):Bool {

		return this.has(listener);

	}

	public inline function destroy() {

		this.destroy();

	}

	public inline function clear() {

		this.clear();

	}

	inline function get_emit():T {

		return this.emit;

	}

	inline function get_handlers():Array<SignalHandler<T>> {

		return this.handlers;

	}

	inline function get_processing():Bool {

		return this.processing;

	}

	@:to 
	static inline function toSignal0(signal:SignalBase<Void->Void>):Signal0 {

		return new Signal0();

	}
	
	@:to 
	static inline function toSignal1<T1>(signal:SignalBase<T1->Void>):Signal1<T1> {

		return new Signal1();

	}
	
	@:to 
	static inline function toSignal2<T1, T2>(signal:SignalBase<T1->T2->Void>):Signal2<T1, T2> {

		return new Signal2();

	}
	
	@:to 
	static inline function toSignal3<T1, T2, T3>(signal:SignalBase<T1->T2->T3->Void>):Signal3<T1, T2, T3> {

		return new Signal3();

	}
	
	@:to 
	static inline function toSignal4<T1, T2, T3, T4>(signal:SignalBase<T1->T2->T3->T4->Void>):Signal4<T1, T2, T3, T4> {

		return new Signal4();

	}

}


class Signal0 extends SignalBase<Void->Void> {
	

	public function new(){

		super();
		this.emit = emit0;

	}

	public function emit0() {

		SignalMacro.buildemit();

	}


}


class Signal1<T1> extends SignalBase<T1->Void> {
	

	public function new(){

		super();
		this.emit = emit1;

	}

	public function emit1(v1:T1) {

		SignalMacro.buildemit(v1);

	}


}

class Signal2<T1, T2> extends SignalBase<T1->T2->Void> {
	

	public function new(){

		super();
		this.emit = emit2;

	}

	public function emit2(v1:T1, v2:T2) {

		SignalMacro.buildemit(v1, v2);

	}


}

class Signal3<T1, T2, T3> extends SignalBase<T1->T2->T3->Void> {
	

	public function new(){

		super();
		this.emit = emit3;

	}

	public function emit3(v1:T1, v2:T2, v3:T3) {

		SignalMacro.buildemit(v1, v2, v3);

	}


}

class Signal4<T1, T2, T3, T4> extends SignalBase<T1->T2->T3->T4->Void> {
	

	public function new(){

		super();
		this.emit = emit4;

	}

	public function emit4(v1:T1, v2:T2, v3:T3, v4:T4) {

		SignalMacro.buildemit(v1, v2, v3, v4);

	}


}

class SignalBase<T> {


	public var emit:T;
	public var handlers:Array<SignalHandler<T>>;
	public var processing:Bool;
	var _to_remove:Array<T>;
	var _to_add:Array<SignalHandler<T>>;


	public function new() {
		
		handlers = [];
		_to_remove = [];
		_to_add = [];
		processing = false;

	}

	public function add_once(listener:T, order:Int = 0) {

		_try_add(listener, true, order);

	}

	public function add(listener:T, order:Int = 0) {

		_try_add(listener, false, order);
		
	}

	public function remove(listener:T) {

		if(has(listener)) {
			if(processing) {
				if(_to_remove.indexOf(listener) == -1) {
					_to_remove.push(listener);
				}
			} else {
				_remove(listener);
			}
		}

	}

	public inline function has(listener:T):Bool {

		return get_handler(listener) != null;
		
	}

	public function get_handler(listener:T):SignalHandler<T> {
		
		for (h in handlers) {
			if(h.listener == listener) {
				return h;
			}
		}

		return null;

	}

	public inline function clear() {
		
		handlers = null;
		_to_remove = null;
		_to_add = null;

		handlers = [];
		_to_remove = [];
		_to_add = [];

	}

	public inline function destroy() {
		
		emit = null;
		handlers = null;
		_to_remove = null;
		_to_add = null;

	}

	inline function _try_add(listener:T, once:Bool, order:Int) {

		if(!has(listener)) {

			var handler = new SignalHandler<T>(listener, once, order);

			if(processing) {
				var has = false;
				for (s in _to_add) {
					if(s.listener == listener) {
						has = true;
						break;
					}
				}
				if(has) {
					_to_add.push(handler);
				}
			} else {
				_add(handler);
			}
		}

	}

	function _add(handler:SignalHandler<T>) {

		var at_pos:Int = handlers.length;

		for (i in 0...handlers.length) {
			if (handler.order < handlers[i].order) {
				at_pos = i;
				break;
			}
		}

		handlers.insert(at_pos, handler);

	}

	function _remove(listener:T) {

		for (i in 0...handlers.length) {
			if(handlers[i].listener == listener) {
				handlers.splice(i, 1);
				break;
			}
		}

	}


}


class SignalHandler<T> {


	public var listener:T;
	public var once:Bool;
	public var order:Int;


	public function new(listener:T, once:Bool, order:Int) {

		this.listener = listener;
		this.once = once;
		this.order = order;

	}


}

#end


private class SignalMacro {

	public static macro function buildemit(exprs:Array<Expr>):Expr {

		return macro { 
			processing = true;

			for (h in handlers){
				h.listener($a{exprs});
				if(h.once) {
					_to_remove.push(h.listener);
				}
			}
			
			processing = false;
			
			if (_to_remove.length > 0){
				for (l in _to_remove){
					_remove(l);
				}
				_to_remove.splice(0, _to_remove.length);
			}

			if (_to_add.length > 0){
				for (h in _to_add){
					_add(h);
				}
				_to_add.splice(0, _to_add.length);
			}
		}

	}

}