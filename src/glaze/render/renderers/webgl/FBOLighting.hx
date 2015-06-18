package glaze.render.renderers.webgl;

import glaze.ds.TypedArray2D;
import glaze.render.texture.BaseTexture;
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

    public var quadVertBuffer:Buffer;

    public var screenShader:ShaderWrapper;
    public var surfaceShader:ShaderWrapper;

    public var camera:Camera;

    public var surface:BaseTexture;

    public var lightData:Float32Array;
    public var lightDataTexture:BaseTexture;

    public var gridResolution:Int = 16;

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
                -1,  1,
                 1,  1,
                 1, -1,

                1,-1,
                -1,-1,
                -1,1


                // -1, -1,
                //  1, -1,
                //  1,  1,

                // -1, -1,
                //  1,  1,
                // -1,  1,
            ]
        );

        gl.bufferData(RenderingContext.ARRAY_BUFFER, quadVerts, RenderingContext.STATIC_DRAW);
       
        gl.bufferData(RenderingContext.ARRAY_BUFFER, quadVerts, RenderingContext.STATIC_DRAW);

        screenShader = new ShaderWrapper(gl, WebGLShaders.CompileProgram(gl,SCREEN_VERTEX_SHADER,SCREEN_FRAGMENT_SHADER));
        surfaceShader = new ShaderWrapper(gl, WebGLShaders.CompileProgram(gl,SURFACE_VERTEX_SHADER,SURFACE_FRAGMENT_SHADER));

        surface = new BaseTexture(gl,Std.int(800/gridResolution),Std.int(640/gridResolution));

        lightData = new Float32Array(8*8*4);
        lightDataTexture = new BaseTexture(gl,8,8,true);

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

    function drawSurface() {
        lightData[0] = 100.0;  //x
        lightData[1] = 320.0;  //y
        lightData[2] = 200;  //dist
        lightData[3] = 0;

        lightData[4] = 700.0;  //x
        lightData[5] = 420.0;  //y
        lightData[6] = 100;  //dist
        lightData[7] = 0;

        lightDataTexture.bind(0);
        gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, 8, 8, 0, RenderingContext.RGBA, RenderingContext.FLOAT, lightData);

        gl.clearColor(0,0,0,0);
        gl.clear(RenderingContext.COLOR_BUFFER_BIT);
        gl.colorMask(true, true, true, true); 
        gl.useProgram(surfaceShader.program);
        gl.uniform2fv(untyped surfaceShader.uniform.viewportSize, scaledViewportSize);
        gl.uniform2f( untyped surfaceShader.uniform.resolution, 800, 640 );
        gl.uniform1i( untyped surfaceShader.uniform.texture,0);
        gl.bindBuffer( RenderingContext.ARRAY_BUFFER, quadVertBuffer );
        gl.vertexAttribPointer(untyped surfaceShader.attribute.position, 2, RenderingContext.FLOAT, false, 0, 0);
        gl.drawArrays(RenderingContext.TRIANGLES, 0, 6);
    }

    public function Render(clip:AABB2) {
        var x = -camera.position.x / (tileScale*2);
        var y = -camera.position.y / (tileScale*2);

        gl.enable(RenderingContext.BLEND);
        gl.blendFunc(RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA);

        surface.drawTo(drawSurface);

        gl.useProgram(screenShader.program);
        gl.uniform2fv(untyped screenShader.uniform.viewportSize, scaledViewportSize);
        gl.uniform2f( untyped screenShader.uniform.resolution, 800, 640 );
        surface.bind(0);
        gl.uniform1i( untyped screenShader.uniform.texture,0);

        gl.bindBuffer( RenderingContext.ARRAY_BUFFER, quadVertBuffer );
        gl.vertexAttribPointer(untyped screenShader.attribute.position, 2, RenderingContext.FLOAT, false, 0, 0);

        gl.drawArrays(RenderingContext.TRIANGLES, 0, 6);
        surface.unbind(0);

    }
    
    public static var SURFACE_VERTEX_SHADER:Array<String> = [
        "precision mediump float;",
        "attribute vec2 position;",

        "void main(void) {",
        "   gl_Position = vec4(position, 0.0, 1.0);",
        "}"
    ];

    public static var SURFACE_FRAGMENT_SHADER:Array<String> = [
       "precision mediump float;",
       "precision mediump int;",

        "uniform sampler2D texture;",
        "uniform vec2 resolution;",

        "float accumulatedLight = 0.0;",

        "void applyLight(vec2 tilePos,vec4 light)",
        "{",
        "   vec2 dist = tilePos-light.xy;",
        "   float intensity = 1.0 - (dist.x*dist.x+dist.y*dist.y)/(light.z*light.z);",
        "   accumulatedLight = max(accumulatedLight,intensity);",
        "}",

        "void main(void) {",
        "   vec2 tilePos = (gl_FragCoord.xy * vec2(16.0,16.0)) + vec2(8.0,8.0);",
        "   float index = 0.0;",
        "   for (int i=0; i<8; i++) {",
        "       vec4 lightData = texture2D(texture,vec2(index,0.0));",
        "       if (lightData.z==0.0) break;", //End of the lights, there should be no lights at this intensity
        "       applyLight(tilePos,lightData);",
        "       index+=1.0/8.0;",
        "   }",
        "   gl_FragColor = vec4 (0.0, 0.0, 0.0, 1.0-accumulatedLight);",
        "}"
    ];


    //Draw to screen programs

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
        //"    gl_FragColor = vec4 (0.0, 1.0, 0.0, 0.5);",
        "    gl_FragColor = texture2D(texture,uv);",
        "}"
    ];

}