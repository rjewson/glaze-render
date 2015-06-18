
package glaze.render.texture;

import haxe.ds.StringMap;
import js.html.Image;
import js.html.webgl.Framebuffer;
import js.html.webgl.Renderbuffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;

class BaseTexture
{

    var gl:RenderingContext;

    public var width:Int;
    public var height:Int;
    public var source:Image;
    public var powerOfTwo:Bool;

    public var texture:Texture;

    public var framebuffer:Framebuffer;
    public var renderbuffer:Renderbuffer;

    public function new(gl:RenderingContext,width:Int,height:Int,floatingPoint:Bool=false) {
        // js.Lib.debug();
        this.gl = gl;
        powerOfTwo = false;
        this.width = width;
        this.height = height;    
        RegisterTexture(floatingPoint);     
    } 

    public function RegisterTexture(fp:Bool) {
        if (texture==null)
            texture = gl.createTexture();
        gl.bindTexture(RenderingContext.TEXTURE_2D,texture);
        gl.pixelStorei(RenderingContext.UNPACK_PREMULTIPLY_ALPHA_WEBGL,0 );
        // gl.pixelStorei(RenderingContext.UNPACK_FLIP_Y_WEBGL, 1);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MAG_FILTER,RenderingContext.NEAREST);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MIN_FILTER,RenderingContext.NEAREST);
        if (powerOfTwo) {
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_S,RenderingContext.REPEAT);
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_T,RenderingContext.REPEAT);
        } else {
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_S,RenderingContext.CLAMP_TO_EDGE);
            gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_T,RenderingContext.CLAMP_TO_EDGE);
        }
        // gl.bindTexture(RenderingContext.TEXTURE_2D,null);
        //gl.texImage2D(RenderingContext.TEXTURE_2D,0,RenderingContext.RGBA,RenderingContext.RGBA,RenderingContext.UNSIGNED_BYTE,source);
        gl.texImage2D(RenderingContext.TEXTURE_2D,0,RenderingContext.RGBA, width, height, 0, RenderingContext.RGBA,fp?RenderingContext.FLOAT:RenderingContext.UNSIGNED_BYTE, null);
    }

    public static function FromImage(gl:RenderingContext,image:Image) {
        var texture = new BaseTexture(gl,image.width,image.height);
        gl.texImage2D(RenderingContext.TEXTURE_2D,0,RenderingContext.RGBA,RenderingContext.RGBA,RenderingContext.UNSIGNED_BYTE,image);
        return texture;
    }

    public function bind(unit:Int) {
        gl.activeTexture(RenderingContext.TEXTURE0 + unit);
        gl.bindTexture(RenderingContext.TEXTURE_2D,texture);
    }

    public function unbind(unit:Int) {
        gl.activeTexture(RenderingContext.TEXTURE0 + unit);
        gl.bindTexture(RenderingContext.TEXTURE_2D,null);
    }


    public function drawTo(callback:Void->Void) {
        //var v = gl.getParameter(RenderingContext.VIEWPORT);
        if (framebuffer==null)
            framebuffer = gl.createFramebuffer();
        if (renderbuffer==null)
            renderbuffer = gl.createRenderbuffer();
        gl.bindFramebuffer(RenderingContext.FRAMEBUFFER,framebuffer);
        gl.bindRenderbuffer(RenderingContext.RENDERBUFFER,renderbuffer);
        if (width != untyped renderbuffer.width || height != untyped renderbuffer.height) {
            untyped renderbuffer.width = width;
            untyped renderbuffer.height = height;
            gl.renderbufferStorage(RenderingContext.RENDERBUFFER, RenderingContext.DEPTH_COMPONENT16, width, height);
            trace("resize");
        }
        gl.framebufferTexture2D(RenderingContext.FRAMEBUFFER, RenderingContext.COLOR_ATTACHMENT0, RenderingContext.TEXTURE_2D, texture, 0);
        gl.framebufferRenderbuffer(RenderingContext.FRAMEBUFFER, RenderingContext.DEPTH_ATTACHMENT, RenderingContext.RENDERBUFFER, renderbuffer);

        gl.viewport(0, 0, width, height);
        callback();
        gl.bindFramebuffer(RenderingContext.FRAMEBUFFER, null);
        gl.bindRenderbuffer(RenderingContext.RENDERBUFFER, null);
        // gl.viewport(v[0], v[1], v[2], v[3]);
        gl.viewport(0, 0, 800, 640);
    }

    public function UnregisterTexture(gl:RenderingContext) {
        if (texture!=null) {
            //texture
        }
    }

}