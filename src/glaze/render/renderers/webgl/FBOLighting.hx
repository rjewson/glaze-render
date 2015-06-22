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
    
    public var gridSize:Int;

    public var texture:Texture;

    public var quadVertBuffer:Buffer;

    public var screenShader:ShaderWrapper;
    public var surfaceShader:ShaderWrapper;

    public var camera:Camera;

    public var surface:BaseTexture;

    public var lightData:Float32Array;
    public var lightDataTexture:BaseTexture;

    public var maxLights:Int = 32;
    public var indexRun:Int;

    public var fullReset:Bool = true;

    public function new()
    {
    }

    public function Init(gl:RenderingContext,camera:Camera) {
        this.gl = gl;
        this.camera = camera;
        gridSize = 4;

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

        surface = new BaseTexture(gl,Std.int(800/gridSize),Std.int(640/gridSize));

        lightData = new Float32Array(maxLights*4*4);
        lightDataTexture = new BaseTexture(gl,lightData.length,1,true);
        reset();
    }

    public function Resize(width:Int,height:Int) {
        viewportSize.x = width;
        viewportSize.y = height;
    }

    public function reset() {
        indexRun = 0;
    }

    public function addLight(x:Float,y:Float,intensity:Float,red:Int,green:Int,blue:Int) {
        lightData[indexRun++] = x;  //x
        lightData[indexRun++] = y;  //y
        lightData[indexRun++] = intensity;  //dist
        lightData[indexRun++] = (red<<16 | green<<8 | blue) / (1<<24);
    }

    function drawSurface() {
        // lightData[0] = 400.0;  //x
        // lightData[1] = 100.0;  //y
        // lightData[2] = 300;  //dist
        // lightData[3] = 0;

        // lightData[4] = 100.0;  //x
        // lightData[5] = 600.0;  //y
        // lightData[6] = 0;  //dist
        // lightData[7] = 0;
        // reset();
        // addLight(400,100,300);
        // addLight(100,600,100);
        addLight(0,0,0,0,0,0);

        var x = camera.position.x;
        var y = camera.position.y;

        lightDataTexture.bind(0);
        gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, 8, 8, 0, RenderingContext.RGBA, RenderingContext.FLOAT, lightData);


        gl.clearColor(1,1,1,1);
        gl.clear(RenderingContext.COLOR_BUFFER_BIT);
        gl.colorMask(true, true, true, true); 
        gl.useProgram(surfaceShader.program);
        // if (fullReset==true) {
        gl.uniform2fv(untyped surfaceShader.uniform.viewportSize, scaledViewportSize);
        gl.uniform2f( untyped surfaceShader.uniform.resolution, 800, 640 );
        gl.uniform2f( untyped surfaceShader.uniform.viewOffset, -x, -y );
        gl.uniform2f( untyped surfaceShader.uniform.gridSize, gridSize, gridSize );
        gl.uniform1i( untyped surfaceShader.uniform.numLights, maxLights );
        // fullReset=false;
        // }
        gl.uniform1i( untyped surfaceShader.uniform.texture,0);
        gl.bindBuffer( RenderingContext.ARRAY_BUFFER, quadVertBuffer );
        gl.vertexAttribPointer(untyped surfaceShader.attribute.position, 2, RenderingContext.FLOAT, false, 0, 0);
        gl.drawArrays(RenderingContext.TRIANGLES, 0, 6);
    }

    public function Render(clip:AABB2) {
        var x = camera.position.x;
        var y = camera.position.y;

        surface.drawTo(drawSurface);

        gl.enable(RenderingContext.BLEND);
        // gl.blendFunc(RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA);
        gl.blendFunc(RenderingContext.DST_COLOR,RenderingContext.ZERO);

        gl.useProgram(screenShader.program);
        gl.uniform2fv(untyped screenShader.uniform.viewportSize, scaledViewportSize);
        gl.uniform2f( untyped screenShader.uniform.resolution, 800, 640 );
        gl.uniform2f( untyped screenShader.uniform.textureOffset,(-x%gridSize), (-y%gridSize) );
        surface.bind(0);
        gl.uniform1i( untyped screenShader.uniform.texture,0);

        gl.bindBuffer( RenderingContext.ARRAY_BUFFER, quadVertBuffer );
        gl.vertexAttribPointer(untyped screenShader.attribute.position, 2, RenderingContext.FLOAT, false, 0, 0);

        gl.drawArrays(RenderingContext.TRIANGLES, 0, 6);
        surface.unbind(0);
        gl.disable(RenderingContext.BLEND);

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
        "uniform vec2 viewOffset;",
        "uniform vec2 gridSize;",
        "uniform int maxLights;",

        "vec4 accumulatedLight = vec4(0.0,0.0,0.0,1.0);",

        "void applyLight(vec2 tilePos,vec4 light)",
        "{",
        "   vec2 dist = tilePos-light.xy;",
        "   float intensity = 1.0 - (dist.x*dist.x+dist.y*dist.y)/(light.z*light.z);",
        "   intensity = clamp(intensity,0.0,1.0);",
        "   intensity = intensity * intensity;",
        "   vec3 unpackedValues = vec3(1.0, 256.0, 65536.0);",
        "   unpackedValues = fract(unpackedValues * light.w);",
        //"   accumulatedLight.xyz +=  unpackedValues*intensity;",//max(accumulatedLight,intensity);",
        "   accumulatedLight.xyz =  max(unpackedValues*intensity,accumulatedLight.xyz);",//max(accumulatedLight,intensity);",
        "}",
        // "void applyLight2(vec2 tilePos,vec4 light)",
        // "{",
        // "   vec2 dist = tilePos-light.xy;",
        // "   float sqrd = (dist.x*dist.x+dist.y*dist.y);",
        // "   float intensityCoef1 = 1.0/(1.0+sqrd/20.0);",
        // "   float intensityCoef2 = intensityCoef1 - 1.0/(1.0+light.z*light.z);",
        // "   float intensityCoef3 = intensityCoef2 / (1.0 - 1.0/(1.0+light.z*light.z));",
        // "   accumulatedLight = max(accumulatedLight,intensityCoef3);",
        // "}",

        "void main(void) {",
        "   vec2 tilePos = viewOffset + (gl_FragCoord.xy * gridSize) + gridSize/2.0;",
        "   float index = 0.0;",
        "   for (int i=0; i<32; i++) {",
        "       vec4 lightData = texture2D(texture,vec2(index,0.0));",
        "       if (lightData.z==0.0) break;", //End of the lights, there should be no lights at this intensity
        "       applyLight(tilePos,lightData);",
        "       index+=1.0/32.0;",
        "   }",
        "   gl_FragColor = accumulatedLight;",//vec4 (accumulatedLight, accumulatedLight, accumulatedLight, 1);",
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
        "uniform vec2 textureOffset;",

        "void main(void) {",
        "    vec2 uv = (gl_FragCoord.xy)/(resolution.xy);",
        "    uv.y = 1.0-uv.y;",
        "    gl_FragColor = texture2D(texture,uv);",
        "}"
    ];

}