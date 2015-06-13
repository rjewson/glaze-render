package glaze.render.renderers.webgl;

import glaze.ds.TypedArray2D;
import js.html.Float32Array;
import js.html.Image;
import js.html.Uint32Array;
import js.html.Uint8Array;
import js.html.webgl.Buffer;
import js.html.webgl.Program;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import glaze.render.display.Camera;
import glaze.geom.Vector2;
import glaze.geom.AABB2;
import glaze.render.renderers.webgl.IRenderer;
import glaze.render.renderers.webgl.ShaderWrapper;
import glaze.render.renderers.webgl.WebGLShaders;
import glaze.render.renderers.webgl.TileLayer;

class FBOLighting implements IRenderer
{
    public var gl:RenderingContext;
    public var viewportSize:Vector2;
    public var scaledViewportSize:Float32Array;
    public var inverseTileTextureSize:Float32Array;

    public var tileScale:Float;
    public var tileSize:Int;
    public var filtered:Bool;

    public var texture:Texture;

    public var fb:js.html.webgl.Framebuffer;
    public var rb:js.html.webgl.Renderbuffer;

    public var quadVertBuffer:Buffer;

    public var screenShader:ShaderWrapper;

    public var camera:Camera;

    public function new()
    {
    }

    public function Init(gl:RenderingContext,camera:Camera) {
        this.gl = gl;
        this.camera = camera;
        tileScale = 1.0;
        tileSize = 16;
        filtered = false;

        viewportSize = new Vector2();
        scaledViewportSize = new Float32Array(2);

        quadVertBuffer = gl.createBuffer();
        gl.bindBuffer(RenderingContext.ARRAY_BUFFER, quadVertBuffer);

        var quadVerts = new js.html.Float32Array(
            [
                -1, -1,
                 1, -1,
                 1,  1,

                -1, -1,
                 1,  1,
                -1,  1,
            ]
        );

        gl.bufferData(RenderingContext.ARRAY_BUFFER, quadVerts, RenderingContext.STATIC_DRAW);
        screenShader = new ShaderWrapper(gl, WebGLShaders.CompileProgram(gl,SCREEN_VERTEX_SHADER,SCREEN_FRAGMENT_SHADER));

        setupFBO();
    }

    public function setupFBO() {
        texture = gl.createTexture();
        fb = gl.createFramebuffer();
        rb = gl.createRenderbuffer();

        gl.bindTexture(RenderingContext.TEXTURE_2D, texture);
        gl.texImage2D(RenderingContext.TEXTURE_2D,0,RenderingContext.RGBA,32,32,0,RenderingContext.RGBA,RenderingContext.UNSIGNED_BYTE,null);

        gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.LINEAR);
        gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.LINEAR); // Worth it to mipmap here?
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_S,RenderingContext.CLAMP_TO_EDGE);
        gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_WRAP_T,RenderingContext.CLAMP_TO_EDGE);

        
        gl.bindFramebuffer(RenderingContext.FRAMEBUFFER,fb);
        gl.framebufferTexture2D(RenderingContext.FRAMEBUFFER,RenderingContext.COLOR_ATTACHMENT0,RenderingContext.TEXTURE_2D,texture,0);

        gl.bindRenderbuffer(RenderingContext.RENDERBUFFER,rb);

        gl.renderbufferStorage(RenderingContext.RENDERBUFFER,RenderingContext.DEPTH_COMPONENT16,32,32);
        gl.framebufferRenderbuffer(RenderingContext.FRAMEBUFFER,RenderingContext.DEPTH_ATTACHMENT,RenderingContext.RENDERBUFFER,rb);

        gl.bindTexture(RenderingContext.TEXTURE_2D,null);
        gl.bindRenderbuffer(RenderingContext.RENDERBUFFER,null);
        gl.bindFramebuffer(RenderingContext.FRAMEBUFFER,null);

    }

    public function Resize(width:Int,height:Int) {
        viewportSize.x = width;
        viewportSize.y = height;
        scaledViewportSize[0] = width/tileScale;
        scaledViewportSize[1] = height/tileScale;
    }

    public function TileScale(scale:Float) {
        this.tileScale = scale;
        scaledViewportSize[0] = viewportSize.x/scale;
        scaledViewportSize[1] = viewportSize.y/scale;
    }

    public function RoundFunction(v:Float):Float {
        return v;
        // return Math.round(v);
        //return Std.int(v);
        //return cast (0.5 + v) >> 0;
        //v-=0.5;
        return Math.round( v * 10) / 10;
    }


    public function Render(clip:AABB2) {
        trace("r");
        var x = -camera.position.x / (tileScale*2);
        var y = -camera.position.y / (tileScale*2);
        //x += tileSize/2;
        //y += tileSize/2;

        gl.enable(RenderingContext.BLEND);
        gl.blendFunc(RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA);

        gl.useProgram(screenShader.program);

        gl.uniform2fv(untyped screenShader.uniform.viewportSize, scaledViewportSize);


gl.uniform2f( untyped screenShader.uniform.resolution, 800, 600 );
gl.uniform1i( untyped screenShader.uniform.texture, 1 );
gl.bindBuffer( RenderingContext.ARRAY_BUFFER, quadVertBuffer );
gl.vertexAttribPointer(untyped screenShader.attribute.position, 2, RenderingContext.FLOAT, false, 0, 0);

gl.activeTexture( RenderingContext.TEXTURE1 );
gl.bindTexture( RenderingContext.TEXTURE_2D, texture );
// Render front buffer to screen
gl.bindFramebuffer( RenderingContext.FRAMEBUFFER, null );
// gl.clear( RenderingContext.COLOR_BUFFER_BIT | RenderingContext.DEPTH_BUFFER_BIT );


        gl.drawArrays(RenderingContext.TRIANGLES, 0, 6);
    }
    
    public static var SCREEN_VERTEX_SHADER:Array<String> = [
        "precision mediump float;",
        "attribute vec2 position;",

        "void main(void) {",
        "   gl_Position = vec4(position, 0.0, 1.0);",
        "}"
    ];

    public static var SCREEN_FRAGMENT_SHADER:Array<String> = [
       "precision mediump float;",

        "uniform sampler2D texture;",
        "uniform vec2 resolution;",

        "void main(void) {",
        "    vec2 uv = gl_FragCoord.xy/resolution.xy;",
        "    gl_FragColor = vec4 (0.0, 1.0, 0.0, 0.5);",
        "    gl_FragColor = texture2D(texture,uv);",
        "}"
    ];

}