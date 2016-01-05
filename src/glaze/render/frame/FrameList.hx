package glaze.render.frame;

import glaze.geom.Vector2;
import glaze.render.texture.Texture;

class FrameList {

	public var frames:Array<Frame>;
	public var framesHash:Map<String, Frame>;
	public var numFrames(get, never):Int;

	public function new() {
		this.frames = new Array<Frame>();
		this.framesHash = new Map<String, Frame>();
	}

	public function addFrame(frame:Frame) {
		frames.push(frame);
		framesHash.set(frame.name, frame);
	}

	private inline function get_numFrames():Int {
		return frames.length;
	}



}