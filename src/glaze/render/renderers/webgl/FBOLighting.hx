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

        surface = new BaseTexture(gl,Std.int(800/32),Std.int(640/32));
// // At init time. Clear the back buffer.
// gl.clearColor(1,1,1,1);
// gl.clear(RenderingContext.COLOR_BUFFER_BIT);

// // Turn off rendering to alpha
// gl.colorMask(true, true, true, false); 
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

    function setCol() {
        gl.clearColor(1,0,0,0.5);
        gl.clear(RenderingContext.COLOR_BUFFER_BIT);
        gl.colorMask(true, true, true, true); 
    }

    function drawSurface() {
        js.Browser.console.time("richard");
        // gl.clearColor(1,0,0,0.5);
        gl.clearColor(0,0,0,0);
        gl.clear(RenderingContext.COLOR_BUFFER_BIT);
        gl.colorMask(true, true, true, true); 
        gl.useProgram(surfaceShader.program);
        gl.uniform2fv(untyped surfaceShader.uniform.viewportSize, scaledViewportSize);
        gl.uniform2f( untyped surfaceShader.uniform.resolution, 800, 600 );
        gl.uniformMatrix3fv( untyped surfaceShader.uniform.lights, false, [ 12.5*32,12.5*32,6*32 ,4*32,4*32,8*32 ,0,0,0 ] );
        gl.bindBuffer( RenderingContext.ARRAY_BUFFER, quadVertBuffer );
        gl.vertexAttribPointer(untyped surfaceShader.attribute.position, 2, RenderingContext.FLOAT, false, 0, 0);
        gl.drawArrays(RenderingContext.TRIANGLES, 0, 6);
        js.Browser.console.timeEnd("richard");
    }

    public function Render(clip:AABB2) {
        var x = -camera.position.x / (tileScale*2);
        var y = -camera.position.y / (tileScale*2);
        //x += tileSize/2;
        //y += tileSize/2;

        // gl.enable(RenderingContext.BLEND);
        // gl.blendFunc(RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA);

        // surface.drawTo(setCol);
        surface.drawTo(drawSurface);

        //gl.useProgram(surfaceShader.program);

        gl.useProgram(screenShader.program);
        gl.uniform2fv(untyped screenShader.uniform.viewportSize, scaledViewportSize);
        gl.uniform2f( untyped screenShader.uniform.resolution, 800, 600 );
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

        "uniform sampler2D texture;",
        "uniform vec2 resolution;",
        "uniform mat3 lights;",

        "float accumulatedLight = 0.0;",

        "void applyLight(vec2 tilePos,vec3 light)",
        "{",
        "   vec2 dist = tilePos-light.xy;",
        "   float intensity = 1.0 - length(dist)/light.z;",
        "   for (int i=0; i<128; i++) {",
        "   accumulatedLight = max(accumulatedLight,intensity);",
        "   }",

        //"   float lightValue = length(dist)/light.z;",
        //"   accumulatedLight = max(accumulatedLight,lightValue);",
        "}",


        "void main(void) {",
        //"    vec2 uv = gl_FragCoord.xy/resolution.xy;",
        //"    gl_FragColor = vec4 (0.0, 0.0, 1.0, 1.0);",
        // "    gl_FragColor = texture2D(texture,uv);",
        "      vec2 tilePos = (gl_FragCoord.xy * vec2(32.0,32.0)) + vec2(16.0,16.0);",
        // "      vec2 lightPos = vec2(lights[0][0],lights[0][1]);",
            //"      vec2 dist = tilePos-lightPos;",
            //"      gl_FragColor = vec4 (0.0, 0.0, 0.0, length(dist)/lights[0][2]);",
        "   applyLight(tilePos,lights[0]);",
        "   applyLight(tilePos,lights[1]);",
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