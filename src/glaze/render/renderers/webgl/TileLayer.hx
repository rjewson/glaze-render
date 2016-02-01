package glaze.render.renderers.webgl;

import glaze.ds.TypedArray2D;
import glaze.render.texture.BaseTexture;
import js.html.Float32Array;
import js.html.Image;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import glaze.geom.Vector2;

class TileLayer
{

    public var scrollScale:Vector2;

    public var tileDataTexture:Texture;
    public var inverseTileDataTextureSize:Float32Array;

    public var spriteTexture:Texture;
    public var inverseSpriteTextureSize:Float32Array;

    public function new()
    {
        scrollScale = new Vector2(1,1);
        inverseTileDataTextureSize = new Float32Array(2);
        inverseSpriteTextureSize = new Float32Array(2);
    }

    public function setSpriteTexture(spriteTexture:BaseTexture) {
        this.spriteTexture = spriteTexture.texture;
        inverseSpriteTextureSize[0] = 1/spriteTexture.width;
        inverseSpriteTextureSize[1] = 1/spriteTexture.height;
    }

    public function setTextureFromMap(gl:RenderingContext,data:TypedArray2D) {
        if (tileDataTexture==null)
            tileDataTexture = gl.createTexture();
        gl.bindTexture(RenderingContext.TEXTURE_2D,tileDataTexture);
        gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, data.w, data.h, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, data.data8);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MAG_FILTER,RenderingContext.NEAREST);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MIN_FILTER,RenderingContext.NEAREST);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_S,RenderingContext.CLAMP_TO_EDGE);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_T,RenderingContext.CLAMP_TO_EDGE);   
        inverseTileDataTextureSize[0] = 1/data.w;
        inverseTileDataTextureSize[1] = 1/data.h;
    }

    public function setTexture(gl:RenderingContext,image:Image,repeat:Bool) {
        if (tileDataTexture==null)
            tileDataTexture = gl.createTexture();
        gl.bindTexture(RenderingContext.TEXTURE_2D,tileDataTexture);
        gl.texImage2D(RenderingContext.TEXTURE_2D,0,RenderingContext.RGBA,RenderingContext.RGBA,RenderingContext.UNSIGNED_BYTE,image);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MAG_FILTER,RenderingContext.NEAREST);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MIN_FILTER,RenderingContext.NEAREST);
        if (repeat) {
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_S,RenderingContext.REPEAT);
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_T,RenderingContext.REPEAT);
        } else {
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_S,RenderingContext.CLAMP_TO_EDGE);
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_T,RenderingContext.CLAMP_TO_EDGE);            
        }

        inverseTileDataTextureSize[0] = 1/image.width;
        inverseTileDataTextureSize[1] = 1/image.height;

    }

}