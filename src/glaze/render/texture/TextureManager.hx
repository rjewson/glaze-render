
package glaze.render.texture;

import haxe.ds.StringMap;
import haxe.xml.Fast;
import js.html.Image;
import js.html.webgl.RenderingContext;
import wgr.geom.Point;
import wgr.geom.Rectangle;
import wgr.texture.BaseTexture;
import utils.EventTarget;
import wgr.texture.Texture;

class TextureManager
{

    public var baseTextures:StringMap<BaseTexture>;
    public var textures:StringMap<Texture>;
    public var total:Int;
    public var gl:RenderingContext;

    public function new(gl:RenderingContext) {
        this.gl = gl;
        baseTextures = new StringMap<BaseTexture>();
        textures = new StringMap<Texture>();
    }

    public function AddTexture(id:String,image:Image):BaseTexture {
        var baseTexture = new BaseTexture(image);
        baseTexture.RegisterTexture(gl);
        baseTextures.set(id,baseTexture);
        return baseTexture;
    }

    public function ParseTexturePackerJSON(textureConfig:Dynamic,id:String) {   
        if (!Std.is(textureConfig, String)) 
            return;

        var baseTexture = baseTextures.get(id);

        var textureData = haxe.Json.parse(textureConfig);

        var fields = Reflect.fields(textureData.frames);
        for (prop in fields) {

            var frame = Reflect.field(textureData.frames, prop);

            textures.set(prop,
                new Texture(baseTexture,
                    new Rectangle(
                        Std.parseInt(frame.frame.x),
                        Std.parseInt(frame.frame.y), 
                        Std.parseInt(frame.frame.w), 
                        Std.parseInt(frame.frame.h)
                    ),
                    new Point(
                        Std.parseFloat(frame.pivot.x),
                        Std.parseFloat(frame.pivot.y)
                    )
                )
            );
        }

    }

    public function ParseTexturesFromTiles(tileSize:Int,id:String) {

    }

}