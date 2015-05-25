package glaze.render.renderers.webgl;

import glaze.ds.TypedArray2D;
import js.html.Float32Array;
import js.html.Image;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import glaze.geom.Vector2;

class TileLayer
{

    public var scrollScale:Vector2;
    public var tileTexture:Texture;
    public var inverseTextureSize:Float32Array;

    public function new()
    {
        scrollScale = new Vector2(1,1);
        inverseTextureSize = new Float32Array(2);
    }

    public function setTextureFromMap(gl:RenderingContext,data:TypedArray2D) {
        if (tileTexture==null)
            tileTexture = gl.createTexture();
        gl.bindTexture(RenderingContext.TEXTURE_2D,tileTexture);
        gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, data.w, data.h, 0, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, data.data8);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MAG_FILTER,RenderingContext.NEAREST);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MIN_FILTER,RenderingContext.NEAREST);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_S,RenderingContext.CLAMP_TO_EDGE);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_T,RenderingContext.CLAMP_TO_EDGE);   
        inverseTextureSize[0] = 1/data.w;
        inverseTextureSize[1] = 1/data.h;
          
    }

    public function setTexture(gl:RenderingContext,image:Image,repeat:Bool) {
        if (tileTexture==null)
            tileTexture = gl.createTexture();
        gl.bindTexture(RenderingContext.TEXTURE_2D,tileTexture);
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

        inverseTextureSize[0] = 1/image.width;
        inverseTextureSize[1] = 1/image.height;

    }

}