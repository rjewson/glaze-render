package glaze.render.frame;

import glaze.geom.Vector2;
import glaze.render.display.Sprite;
import glaze.render.texture.Texture;

class Frame {

	public var name:String;
	public var texture:Texture;
	public var scale:Vector2;
	// public var 

	public function new(name:String,texture:Texture) {
		this.name = name;
		this.texture = texture;
	}

	public function updateSprite(sprite:Sprite) {
		sprite.texture = texture;
		sprite.pivot.x = sprite.texture.frame.width * sprite.texture.pivot.x;
        sprite.pivot.y = (sprite.texture.frame.height + 2) * sprite.texture.pivot.y;
	}

}