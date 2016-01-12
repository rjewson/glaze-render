package glaze.render.frame;

import glaze.geom.Vector2;
import glaze.render.animation.Animation;
import glaze.render.texture.Texture;
import glaze.render.texture.TextureManager;

typedef JSONFrames = {
    var id:String;
    var name:String;
    var scale:Vector2;
}

typedef JSONAnimation = {
    var frames:Array<Int>;
    var fps:Int;
    var looped:Bool;
}

typedef JSONFrameList = {
    var frames:Array<JSONFrames>;
    var animations:Array<JSONAnimation>;
}

class FrameListManager {

    public var textureManager:TextureManager;
	public var frameLists:Map<String, FrameList>;

	public function new(textureManager:TextureManager) {
        this.textureManager = textureManager;
		this.frameLists = new Map<String, FrameList>();
	}

    public function getFrameList(id:String) {
        return frameLists.get(id);
    }

	public function ParseFrameListJSON(frameListConfig:Dynamic) {   
        if (!Std.is(frameListConfig, String)) 
            return;

        var frameListConfigData = haxe.Json.parse(frameListConfig);

        var fields = Reflect.fields(frameListConfigData);
        for (prop in fields) {

            var frameList = new FrameList();
            frameLists.set(prop,frameList);

            var framelistItem:JSONFrameList = Reflect.field(frameListConfigData, prop);
            trace(framelistItem.frames);
            if (framelistItem.frames!=null) {
                for (frame in framelistItem.frames) {
                    frameList.addFrame(new Frame(frame.id,textureManager.textures.get(frame.name),frame.scale ));
                }
                if (framelistItem.animations!=null) {
                    // js.Lib.debug();
                    var animations = Reflect.fields(framelistItem.animations);

                    for (animationProp in animations) {
                        var animation:JSONAnimation = Reflect.field(framelistItem.animations, animationProp);
                        // trace(animation);
                        frameList.addAnimation(new Animation(null,animationProp,animation.frames,animation.fps,animation.looped));
                    }
                }
            }
        }
    }

}