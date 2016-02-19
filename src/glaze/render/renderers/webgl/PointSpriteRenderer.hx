
package glaze.render.renderers.webgl;

import js.html.ArrayBuffer;
import js.html.Float32Array;
import js.html.Uint8ClampedArray;
import js.html.webgl.Buffer;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import glaze.render.display.Camera;
import glaze.render.display.Stage;
import glaze.geom.Vector2;
import glaze.geom.AABB2;
import glaze.render.renderers.webgl.ShaderWrapper;

class PointSpriteRenderer implements IRenderer
{

    public var gl:RenderingContext;

    public var projection:Vector2;

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
    public var maxSprites:Int;

    public function new(size:Int) {
        maxSprites = size;
    }

    public function Init(gl:RenderingContext,camera:Camera) {
        this.gl = gl;
        this.camera = camera;
        projection = new Vector2();
        pointSpriteShader = new ShaderWrapper(gl, WebGLShaders.CompileProgram(gl,SPRITE_VERTEX_SHADER,SPRITE_FRAGMENT_SHADER));
        dataBuffer =  gl.createBuffer();
        arrayBuffer = new ArrayBuffer(20*4*maxSprites);
        data = new Float32Array(arrayBuffer);
        data8 = new Uint8ClampedArray(arrayBuffer);
        gl.bindBuffer(RenderingContext.ARRAY_BUFFER,dataBuffer);
        gl.bufferData(RenderingContext.ARRAY_BUFFER,data,RenderingContext.DYNAMIC_DRAW);
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

    // public function AddSpriteToBatch(spriteID:Int,x:Float,y:Float,size:Float,alpha:Int,red:Int,green:Int,blue:Int) {
    //     var index = indexRun * 5;
    //     data[index+0] = Std.int(x + camera.position.x);
    //     data[index+1] = Std.int(y + camera.position.y);
    //     data[index+2] = size;
    //     data[index+3] = spriteID;
    //     index *= 4;
    //     data8[index+16] = red;
    //     data8[index+17] = blue;
    //     data8[index+18] = green;
    //     data8[index+19] = alpha;
    //     indexRun++;
    // }    

    public function AddSpriteToBatch(spriteX:Float,spriteY:Float,width:Float,height:Float,x:Float,y:Float,size:Float,alpha:Int,flipX:Int,flipY:Int,nop:Int) {
        var index = indexRun * 7;
        data[index+0] = Std.int(x + camera.position.x);
        data[index+1] = Std.int(y + camera.position.y);
        data[index+2] = size;
        data[index+3] = spriteX+(width*Math.min(flipX,0)*-1);
        data[index+4] = spriteY+(height*Math.min(flipY,0)*-1);
        data[index+5] = width*flipX;
        data[index+6] = height*flipY;
        // index *= 7;
        // data8[index+28] = 1;
        // data8[index+29] = 1;
        // data8[index+30] = 1;
        // data8[index+31] = 1;
        indexRun++;
    }

    public function Render(clip:AABB2) {

        gl.enable(RenderingContext.BLEND);
        gl.blendFunc(RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA);

        gl.useProgram(pointSpriteShader.program);

        gl.bindBuffer(RenderingContext.ARRAY_BUFFER,dataBuffer);
        gl.bufferSubData(RenderingContext.ARRAY_BUFFER,0,data);

        gl.enableVertexAttribArray(untyped pointSpriteShader.attribute.position);
        gl.enableVertexAttribArray(untyped pointSpriteShader.attribute.size);
        gl.enableVertexAttribArray(untyped pointSpriteShader.attribute.tilePosition);
        gl.enableVertexAttribArray(untyped pointSpriteShader.attribute.tileDimension);
        // gl.enableVertexAttribArray(untyped pointSpriteShader.attribute.colour);

        gl.vertexAttribPointer(untyped pointSpriteShader.attribute.position, 2, RenderingContext.FLOAT, false, 28, 0);
        gl.vertexAttribPointer(untyped pointSpriteShader.attribute.size, 1, RenderingContext.FLOAT, false, 28, 8);
        gl.vertexAttribPointer(untyped pointSpriteShader.attribute.tilePosition, 2, RenderingContext.FLOAT, false, 28, 12);
        gl.vertexAttribPointer(untyped pointSpriteShader.attribute.tileDimension, 2, RenderingContext.FLOAT, false, 28, 20);
        // gl.vertexAttribPointer(untyped pointSpriteShader.attribute.colour, 4, RenderingContext.UNSIGNED_BYTE, false, 28, 28);

        gl.uniform2f(untyped pointSpriteShader.uniform.projectionVector,projection.x,projection.y);            
        // gl.uniform2f(untyped pointSpriteShader.uniform.flip,1,1);            

        gl.activeTexture(RenderingContext.TEXTURE0);
        gl.bindTexture(RenderingContext.TEXTURE_2D,texture);
        gl.drawArrays(RenderingContext.POINTS,0,indexRun);
    }

    public static var SPRITE_VERTEX_SHADER:Array<String> = [
        "precision mediump float;",
        "uniform vec2 projectionVector;",
        // "uniform vec2 flip;",

        "attribute vec2 position;",
        "attribute float size;",
        "attribute vec2 tilePosition;",
        "attribute vec2 tileDimension;",
        "attribute vec2 colour;",
        "varying vec2 vTilePos;",
        "varying vec2 tileDim;",
        // "varying vec2 vColor;",
        "void main() {",
            "vTilePos = tilePosition;",
            "tileDim = tileDimension;",
            "gl_PointSize = size;",
            // "vColor = colour;",
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
        // "uniform vec2 flip;",
        "varying vec2 vTilePos;",
        "varying vec2 tileDim;",
        // "varying vec2 vColor;",
        "void main() {",
            "vec2 uv = vec2( gl_PointCoord.x*tileDim.x + vTilePos.x, gl_PointCoord.y*tileDim.y + vTilePos.y );",
            
            //Latest
            //"vec2 uv = vec2( ((-1.0+(2.0*vColor.x))*(vColor.x-gl_PointCoord.x)*tileDim.x) + vTilePos.x, ((-1.0+(2.0*vColor.y))*(vColor.y-gl_PointCoord.y)*tileDim.y) + vTilePos.y);",
            
            //"vec2 uv = vec2( gl_PointCoord.x*tileDim.x + vTilePos.x, gl_PointCoord.y*tileDim.y + vTilePos.y);", //Works no rotation
            // "vec2 uv = vec2( gl_PointCoord.x*invTexTilesWide + invTexTilesWide*vTilePos.x, gl_PointCoord.y*invTexTilesHigh + invTexTilesHigh*vTilePos.y);",
            //"vec2 uv = vec2( (-1.0*(0.0-gl_PointCoord.x))*invTexTilesWide + invTexTilesWide*vTilePos.x, (gl_PointCoord.y)*invTexTilesHigh + invTexTilesHigh*vTilePos.y);",
            // "vec2 uv = vec2( ((-1.0+(2.0*flip.x))*(flip.x-gl_PointCoord.x))*invTexTilesWide + invTexTilesWide*vTilePos.x, ((-1.0+(2.0*flip.y))*(flip.y-gl_PointCoord.y))*invTexTilesHigh + invTexTilesHigh*vTilePos.y);",
            "gl_FragColor = texture2D( texture, uv );",
        "}"
    ];

}   