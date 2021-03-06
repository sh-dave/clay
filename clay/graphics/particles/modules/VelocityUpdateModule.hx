package clay.graphics.particles.modules;

import clay.graphics.particles.core.ParticleModule;
import clay.graphics.particles.core.Particle;
import clay.graphics.particles.core.Components;
import clay.graphics.particles.components.Velocity;
import clay.utils.Mathf;
import clay.math.Vector;
import clay.math.Rectangle;


class VelocityUpdateModule extends ParticleModule {


	public var damping:Float = 0;

	var _velComps:Components<Velocity>;


	public function new(options:VelocityUpdateModuleOptions) {

		super({});

		damping = options.damping != null ? options.damping : 0;

	}

	override function init() {
		
		_velComps = emitter.components.get(Velocity);
		
	}

	override function update(dt:Float) {

		var v:Velocity;
		var pd:Particle;
		for (p in particles) {
			v = _velComps.get(p.id);
			v.multiplyScalar(Mathf.clamp(1 - dt * damping, 0, 1));
			p.x += v.x * dt;
			p.y += v.y * dt;
		}

	}


}


typedef VelocityUpdateModuleOptions = {

	>ParticleModuleOptions,
	
	@:optional var damping:Float;

}

