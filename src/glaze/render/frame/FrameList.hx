package glaze.render.frame;

import glaze.geom.Vector2;
import glaze.render.animation.Animation;
import glaze.render.texture.Texture;

class FrameList {

	public var frames:Array<Frame>;
	public var framesHash:Map<String, Frame>;
	public var numFrames(get, never):Int;

	public var animationsHash:Map<String,Animation>;

	public function new() {
		this.frames = new Array<Frame>();
		this.framesHash = new Map<String, Frame>();
		this.animationsHash = new Map<String,Animation>();
	}

	public function addFrame(frame:Frame) {
		frames.push(frame);
		framesHash.set(frame.name, frame);
	}

	public function getFrame(id:String) {
		return framesHash.get(id);
	}

	public function addAnimation(animation:Animation) {
		animationsHash.set(animation.name, animation);
	}

	public function getAnimation(id:String) {
		return animationsHash.get(id);
	}

	private inline function get_numFrames():Int {
		return frames.length;
	}



}