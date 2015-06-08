
package glaze.render.renderers.webgl;

import js.html.ArrayBuffer;
import js.html.Float32Array;
import js.html.Uint8ClampedArray;
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import wgr.display.Camera;
import wgr.display.Stage;
import wgr.geom.Point;
import wgr.geom.AABB;
import wgr.renderers.webgl.ShaderWrapper;

class PointSpriteRenderer implements IRenderer
{

    public var gl:RenderingContext;

    public var projection:Point;

    public var pointSpriteShader:ShaderWrapper;
    
    public var dataBuffer:Buffer;
    private var arrayBuffer:ArrayBuffer;
    public var data:Float32Array;
    public var data8:Uint8ClampedArray;

    public var stage:Stage;
    public var camera:Camera;
    public var texture:Texture;

    public var tileSize:Float;
    public var texTilesWide:Float;
    public var texTilesHigh:Float;
    public var invTexTilesWide:Float;
    public var invTexTilesHigh:Float;

    public var indexRun:Int;

    public function new() {
    }

    public function Init(gl:RenderingContext,camera:Camera) {
        this.gl = gl;
        this.camera = camera;
        projection = new Point();
        pointSpriteShader = new ShaderWrapper(gl, WebGLShaders.CompileProgram(gl,SPRITE_VERTEX_SHADER,SPRITE_FRAGMENT_SHADER));
        dataBuffer =  gl.createBuffer();
    }

    public function ResizeBatch(size:Int) {
        arrayBuffer = new ArrayBuffer(20*4*size);
        data = new Float32Array(arrayBuffer);
        data8 = new Uint8ClampedArray(arrayBuffer);
        ResetBatch();
    }

    public function SetSpriteSheet(texture:Texture,spriteSize:Int,spritesWide:Int,spritesHigh:Int) {
        this.texture = texture;
        tileSize = spriteSize;
        texTilesWide = spritesWide;
        texTilesHigh = spritesHigh;
        invTexTilesWide = 1/texTilesWide;
        invTexTilesHigh = 1/texTilesHigh;
    }

    public function Resize(width:Int,height:Int) {
        projection.x = width/2;
        projection.y = height/2;
    }

    public function AddStage(stage:Stage) {
        this.stage = stage;
    }

    public function ResetBatch() {
        indexRun=0;
    }

    public function AddSpriteToBatch(spriteID:Int,x:Float,y:Float,size:Float,alpha:Int,red:Int,green:Int,blue:Int) {
        var index = indexRun * 5;
        data[index+0] = Std.int(x + camera.position.x);
        data[index+1] = Std.int(y + camera.position.y);
        data[index+2] = size;
        data[index+3] = spriteID;
        index *= 4;
        data8[index+16] = red;
        data8[index+17] = blue;
        data8[index+18] = green;
        data8[index+19] = alpha;
        indexRun++;
    }

    public function Render(clip:AABB) {
        // js.Lib.debug();

        gl.enable(RenderingContext.BLEND);
        gl.blendFunc(RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA);

        gl.useProgram(pointSpriteShader.program);
        gl.bindBuffer(RenderingContext.ARRAY_BUFFER,dataBuffer);
        gl.bufferData(RenderingContext.ARRAY_BUFFER,data,RenderingContext.DYNAMIC_DRAW);    

        gl.enableVertexAttribArray(untyped pointSpriteShader.attribute.position);
        gl.enableVertexAttribArray(untyped pointSpriteShader.attribute.size);
        gl.enableVertexAttribArray(untyped pointSpriteShader.attribute.tileType);
        gl.enableVertexAttribArray(untyped pointSpriteShader.attribute.colour);

        gl.vertexAttribPointer(untyped pointSpriteShader.attribute.position, 2, RenderingContext.FLOAT, false, 20, 0);
        gl.vertexAttribPointer(untyped pointSpriteShader.attribute.size, 1, RenderingContext.FLOAT, false, 20, 8);
        gl.vertexAttribPointer(untyped pointSpriteShader.attribute.tileType, 1, RenderingContext.FLOAT, false, 20, 12);
        gl.vertexAttribPointer(untyped pointSpriteShader.attribute.colour, 4, RenderingContext.UNSIGNED_BYTE, true, 20, 16);

        gl.uniform1f(untyped pointSpriteShader.uniform.texTilesWide, texTilesWide);
        gl.uniform1f(untyped pointSpriteShader.uniform.texTilesHigh, texTilesHigh);
        gl.uniform1f(untyped pointSpriteShader.uniform.invTexTilesWide, invTexTilesWide);
        gl.uniform1f(untyped pointSpriteShader.uniform.invTexTilesHigh, invTexTilesHigh);
        gl.uniform2f(untyped pointSpriteShader.uniform.projectionVector,projection.x,projection.y);            
        gl.uniform2f(untyped pointSpriteShader.uniform.flip,0,0);            

        gl.activeTexture(RenderingContext.TEXTURE0);
        gl.bindTexture(RenderingContext.TEXTURE_2D,texture);
        gl.drawArrays(RenderingContext.POINTS,0,indexRun);
    }

    public static var SPRITE_VERTEX_SHADER:Array<String> = [
        "precision mediump float;",
        "uniform float texTilesWide;",
        "uniform float texTilesHigh;",
        "uniform float invTexTilesWide;",
        "uniform float invTexTilesHigh;",
        "uniform vec2 projectionVector;",
        "uniform vec2 flip;",

        "attribute vec2 position;",
        "attribute float size;",
        "attribute float tileType;",
        "attribute vec4 colour;",
        "varying vec2 vTilePos;",
        "varying vec4 vColor;",
        "void main() {",
            "float t = floor(tileType/texTilesWide);",
            "vTilePos = vec2(tileType-(t*texTilesWide), t);",
            "gl_PointSize = size;",
            "vColor = colour;",
            "gl_Position = vec4( position.x / projectionVector.x -1.0, position.y / -projectionVector.y + 1.0 , 0.0, 1.0);",            
        "}",
    ];

/*
normal:  -1 * 0-pc.y
flip:     1 * 1-pc.y

-1 + 2*0

fx = 0
    (-1+(2*fx)) * (fx-pc.x)
    (-1+(2*0)) *  (0-pc.x)
    -1 * (0-pc.x)

fy = 1
    (-1+(2*fx)) * (fx-pc.x)
    (-1+(2*1)) * (1-pc.y)
    1 * (1-pc.y)


*/

    public static var SPRITE_FRAGMENT_SHADER:Array<String> = [
        "precision mediump float;",
        "uniform sampler2D texture;",
        "uniform float invTexTilesWide;",
        "uniform float invTexTilesHigh;",
        "uniform vec2 flip;",

        "varying vec2 vTilePos;",
        "varying vec4 vColor;",
        "void main() {",
            //"vec2 uv = vec2( (-1.0*(0.0-gl_PointCoord.x))*invTexTilesWide + invTexTilesWide*vTilePos.x, (gl_PointCoord.y)*invTexTilesHigh + invTexTilesHigh*vTilePos.y);",
            "vec2 uv = vec2( ((-1.0+(2.0*flip.x))*(flip.x-gl_PointCoord.x))*invTexTilesWide + invTexTilesWide*vTilePos.x, ((-1.0+(2.0*flip.y))*(flip.y-gl_PointCoord.y))*invTexTilesHigh + invTexTilesHigh*vTilePos.y);",
            "gl_FragColor = texture2D( texture, uv ) * vColor;",
        "}"
    ];

}   