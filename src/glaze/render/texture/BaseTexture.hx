
package glaze.render.texture;

import haxe.ds.StringMap;
import js.html.Image;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
// import utils.EventTarget;

class BaseTexture
{
    public var width:Float;
    public var height:Float;
    public var source:Image;
    public var resolution:Int;
    public var powerOfTwo:Bool;

    public var texture:Texture;

    public function new(source:Image) {
        this.source = source;
        powerOfTwo = false;
        resolution = 1;
        width = source.width;
        height = source.width;         
    }

    public function RegisterTexture(gl:RenderingContext) {
        if (texture==null)
            texture = gl.createTexture();
        gl.bindTexture(RenderingContext.TEXTURE_2D,texture);
        gl.pixelStorei(RenderingContext.UNPACK_PREMULTIPLY_ALPHA_WEBGL,1);
        gl.texImage2D(RenderingContext.TEXTURE_2D,0,RenderingContext.RGBA,RenderingContext.RGBA,RenderingContext.UNSIGNED_BYTE,source);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MAG_FILTER,RenderingContext.NEAREST);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MIN_FILTER,RenderingContext.NEAREST);
        if (powerOfTwo) {
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_S,RenderingContext.REPEAT);
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_T,RenderingContext.REPEAT);
        } else {
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_S,RenderingContext.CLAMP_TO_EDGE);
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_T,RenderingContext.CLAMP_TO_EDGE);
        }
        gl.bindTexture(RenderingContext.TEXTURE_2D,null);
    }

    public function UnregisterTexture(gl:RenderingContext) {
        if (texture!=null) {
            //texture
        }
    }

}