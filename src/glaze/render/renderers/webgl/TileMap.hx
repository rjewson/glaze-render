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

class TileMap implements IRenderer
{
    public var gl:RenderingContext;
    public var viewportSize:Vector2;
    public var scaledViewportSize:Float32Array;
    public var inverseTileTextureSize:Float32Array;
    public var inverseSpriteTextureSize:Float32Array;

    public var tileScale:Float;
    public var tileSize:Int;
    public var filtered:Bool;

    public var spriteSheet:Texture;

    public var quadVertBuffer:Buffer;

    public var layers:Array<TileLayer>;

    public var tilemapShader:ShaderWrapper;

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
        spriteSheet = gl.createTexture();
        layers = new Array<TileLayer>();

        viewportSize = new Vector2();
        scaledViewportSize = new Float32Array(2);
        inverseTileTextureSize = new Float32Array(2);
        inverseSpriteTextureSize = new Float32Array(2);

        quadVertBuffer = gl.createBuffer();
        gl.bindBuffer(RenderingContext.ARRAY_BUFFER, quadVertBuffer);

        var quadVerts = new js.html.Float32Array(
            [
                -1, -1, 0, 1,
                 1, -1, 1, 1,
                 1,  1, 1, 0,

                -1, -1, 0, 1,
                 1,  1, 1, 0,
                -1,  1, 0, 0
            ]
        );

        gl.bufferData(RenderingContext.ARRAY_BUFFER, quadVerts, RenderingContext.STATIC_DRAW);
        tilemapShader = new ShaderWrapper(gl, WebGLShaders.CompileProgram(gl,TILEMAP_VERTEX_SHADER,TILEMAP_FRAGMENT_SHADER));
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

    public function Filtered(filtered:Bool) {
        this.filtered = filtered;
        gl.bindTexture(RenderingContext.TEXTURE_2D,spriteSheet);
        if(filtered) {
            gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.NEAREST);
            gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.NEAREST);
        } else {
            gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.LINEAR);
            gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.LINEAR); // Worth it to mipmap here?
        }        
    }

    public function SetSpriteSheet(image:Image) {
        gl.bindTexture(RenderingContext.TEXTURE_2D, spriteSheet);
        gl.texImage2D(RenderingContext.TEXTURE_2D, 0, RenderingContext.RGBA, RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE, image);        
        if(!filtered) {
            gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.NEAREST);
            gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.NEAREST);
        } else {
            gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MAG_FILTER, RenderingContext.LINEAR);
            gl.texParameteri(RenderingContext.TEXTURE_2D, RenderingContext.TEXTURE_MIN_FILTER, RenderingContext.LINEAR); // Worth it to mipmap here?
        }  
        inverseSpriteTextureSize[0] = 1/image.width;
        inverseSpriteTextureSize[1] = 1/image.height;
    }

    public function SetTileLayer(image:Image,layerId:String,scrollScaleX:Float,scrollScaleY:Float) {
        var layer = new TileLayer();
        layer.setTexture(gl,image,false);
        layer.scrollScale.x = scrollScaleX;
        layer.scrollScale.y = scrollScaleY;
        layers.push(layer);
    }

    public function SetTileLayerFromData(data:TypedArray2D,layerId:String,scrollScaleX:Float,scrollScaleY:Float) {
        var layer = new TileLayer();
        layer.setTextureFromMap(gl,data);
        layer.scrollScale.x = scrollScaleX;
        layer.scrollScale.y = scrollScaleY;
        layers.push(layer);
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
        var x = -camera.position.x / (tileScale*2);
        var y = -camera.position.y / (tileScale*2);
        //x += tileSize/2;
        //y += tileSize/2;

        gl.enable(RenderingContext.BLEND);
        gl.blendFunc(RenderingContext.SRC_ALPHA, RenderingContext.ONE_MINUS_SRC_ALPHA);

        gl.useProgram(tilemapShader.program);

        gl.bindBuffer(RenderingContext.ARRAY_BUFFER, quadVertBuffer);

        gl.enableVertexAttribArray(untyped tilemapShader.attribute.position);
        gl.enableVertexAttribArray(untyped tilemapShader.attribute.texture);
        gl.vertexAttribPointer(untyped tilemapShader.attribute.position, 2, RenderingContext.FLOAT, false, 16, 0);
        gl.vertexAttribPointer(untyped tilemapShader.attribute.texture, 2, RenderingContext.FLOAT, false, 16, 8);

        gl.uniform2fv(untyped tilemapShader.uniform.viewportSize, scaledViewportSize);
        gl.uniform2fv(untyped tilemapShader.uniform.inverseSpriteTextureSize, inverseSpriteTextureSize);
        gl.uniform1f(untyped tilemapShader.uniform.tileSize, tileSize);
        gl.uniform1f(untyped tilemapShader.uniform.inverseTileSize, 1/tileSize);

        gl.activeTexture(RenderingContext.TEXTURE0);
        gl.uniform1i(untyped tilemapShader.uniform.sprites, 0);
        gl.bindTexture(RenderingContext.TEXTURE_2D, spriteSheet);

        gl.activeTexture(RenderingContext.TEXTURE1);
        gl.uniform1i(untyped tilemapShader.uniform.tiles, 1);    

        var i = layers.length; 
        while (i>0) {
            i--; 
            var layer = layers[i];
            var pX = RoundFunction(x * tileScale * layer.scrollScale.x);
            var pY = RoundFunction(y * tileScale * layer.scrollScale.y);
            gl.uniform2f(untyped tilemapShader.uniform.viewOffset, pX, pY);
            gl.uniform2fv(untyped tilemapShader.uniform.inverseTileTextureSize, layer.inverseTextureSize);
            gl.bindTexture(RenderingContext.TEXTURE_2D, layer.tileTexture);
            gl.drawArrays(RenderingContext.TRIANGLES, 0, 6);
        }
    }
    
    public static var TILEMAP_VERTEX_SHADER:Array<String> = [
        "precision mediump float;",
        "attribute vec2 position;",
        "attribute vec2 texture;",
        
        "varying vec2 pixelCoord;",
        "varying vec2 texCoord;",

        "uniform vec2 viewOffset;",
        "uniform vec2 viewportSize;",
        "uniform vec2 inverseTileTextureSize;",
        "uniform float inverseTileSize;",

        "void main(void) {",
        "   pixelCoord = (texture * viewportSize) + viewOffset;",
        "   texCoord = pixelCoord * inverseTileTextureSize * inverseTileSize;",
        "   gl_Position = vec4(position, 0.0, 1.0);",
        "}"
    ];

    public static var TILEMAP_FRAGMENT_SHADER:Array<String> = [
       "precision mediump float;",

        "varying vec2 pixelCoord;",
        "varying vec2 texCoord;",

        "uniform sampler2D tiles;",
        "uniform sampler2D sprites;",

        "uniform vec2 inverseTileTextureSize;",
        "uniform vec2 inverseSpriteTextureSize;",
        "uniform float tileSize;",

        "void main(void) {",
        "   vec4 tile = texture2D(tiles, texCoord);",
        "   if(tile.x == 1.0 && tile.y == 1.0) { discard; }",
        "   vec2 spriteOffset = floor(tile.xy * 256.0) * tileSize;",
        "   vec2 spriteCoord = mod(pixelCoord, tileSize);",
        "   gl_FragColor = texture2D(sprites, (spriteOffset + spriteCoord) * inverseSpriteTextureSize);",
        "}"
    ];

}