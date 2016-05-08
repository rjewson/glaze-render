package glaze.render.renderers.webgl;

import glaze.ds.TypedArray2D;
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
    public var renderLayers:Array<TileLayerRenderProxy>;

    public var tilemapShader:ShaderWrapper;

    public var camera:Camera;

    var writebuffer:Uint8Array;

    var writebuffer2:TypedArray2D;

    var flip:Bool;


    public function new()
    {
    }

    public function Init(gl:RenderingContext,camera:Camera) {
        if (this.gl!=null)
            return;
        this.gl = gl;
        this.camera = camera;
        tileScale = 1.0;
        tileSize = 8;
        filtered = false;
        spriteSheet = gl.createTexture();
        layers = new Array<TileLayer>();
        renderLayers = new Array<TileLayerRenderProxy>();

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

        writebuffer = new Uint8Array(2*2*4);
        // writebuffer[0] = 0;
        // writebuffer[1] = 0;
        // writebuffer[2] = 0;
        // writebuffer[3] = 0;
        flip = false;

        writebuffer2 = new TypedArray2D(3,3); //Max 3x3 tileset changes


    }

    public function Resize(width:Int,height:Int) {
        width=400;
        height=320;
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

    public function SetSpriteSheet(image:Image) {
        gl.bindTexture(RenderingContext.TEXTURE_2D, spriteSheet);
        gl.pixelStorei(RenderingContext.UNPACK_PREMULTIPLY_ALPHA_WEBGL,0 );
        // gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MAG_FILTER,RenderingContext.NEAREST);
        // gl.texParameteri(RenderingContext.TEXTURE_2D,RenderingContext.TEXTURE_MIN_FILTER,RenderingContext.NEAREST);
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

    public function SetTileLayerFromData(data:TypedArray2D,sprite:BaseTexture,layerId:String,scrollScaleX:Float,scrollScaleY:Float) {
        var layer = new TileLayer();
        layer.setTextureFromMap(gl,data);
        layer.setSpriteTexture(sprite);
        layer.scrollScale.x = scrollScaleX;
        layer.scrollScale.y = scrollScaleY;
        layers.push(layer);
    }

    public function SetTileRenderLayer(layers:Array<Int>) {
        var tileRenderLayer = new glaze.render.renderers.webgl.TileLayerRenderProxy(null,layers);
        renderLayers.push(tileRenderLayer);
    }

    // public function RoundFunction(v:Float):Float {
    //     var i = Math.round(v);
    // }

    public function updateMap(x:Int, y:Int, data:Array<Int>) {
        // js.Lib.debug();

        var startX  = data[0];
        var startY  = data[1];
        var width   = data[2];
        var height  = data[3];
        var centerX = data[4];
        var centerY = data[5];
        var superY  = Math.floor(data[6]/8);
        var superX  = data[6] % 8;

        writebuffer2.h = height;
        writebuffer2.w = width;

        for (ypos in 0...height) {
            for (xpos in 0...width) {
                var _x = startX+xpos;
                var _y = startY+ypos;
                var value = superY << 24 | superX << 16 | _y << 8 | _x;
                writebuffer2.set(xpos,ypos,value);
            }
        }

        var writeLayer = layers[2].tileDataTexture;
        gl.bindTexture(RenderingContext.TEXTURE_2D, writeLayer); 
        gl.texSubImage2D(RenderingContext.TEXTURE_2D, 0,
                   x-centerX, y-centerY, width , height,
                   RenderingContext.RGBA, RenderingContext.UNSIGNED_BYTE,
                   writebuffer2.data8);
    }

    public function Render(clip:AABB2) {
    }



    public function RenderLayers(clip:AABB2,layerIndexes:Array<Int>,p:Vector2) {

        gl.colorMask(true, true, true, true); 
        gl.clearColor(0,0,0,0);
        gl.clear(RenderingContext.COLOR_BUFFER_BIT);
 
        gl.useProgram(tilemapShader.program);

        gl.bindBuffer(RenderingContext.ARRAY_BUFFER, quadVertBuffer);

        gl.enableVertexAttribArray(untyped tilemapShader.attribute.position);
        gl.enableVertexAttribArray(untyped tilemapShader.attribute.texture);
        gl.vertexAttribPointer(untyped tilemapShader.attribute.position, 2, RenderingContext.FLOAT, false, 16, 0);
        gl.vertexAttribPointer(untyped tilemapShader.attribute.texture, 2, RenderingContext.FLOAT, false, 16, 8);

        gl.uniform2fv(untyped tilemapShader.uniform.viewportSize, scaledViewportSize);
        gl.uniform1f(untyped tilemapShader.uniform.tileSize, tileSize);
        gl.uniform1f(untyped tilemapShader.uniform.inverseTileSize, 1/tileSize);

        gl.uniform1i(untyped tilemapShader.uniform.sprites, 0);
        gl.uniform1i(untyped tilemapShader.uniform.tiles, 1);    

        for (i in layerIndexes) {
        // var i = layers.length; 
        // while (i>0) {
        //     i--; 
            var layer = layers[i];
            // var pX = RoundFunction(x * tileScale * layer.scrollScale.x);
            // var pY = RoundFunction(y * tileScale * layer.scrollScale.y);
            var pX = p.x/2;
            var pY = p.y/2;

            gl.uniform2f(untyped tilemapShader.uniform.viewOffset, pX, pY);
            gl.uniform2fv(untyped tilemapShader.uniform.inverseSpriteTextureSize, layer.inverseSpriteTextureSize);
            gl.uniform2fv(untyped tilemapShader.uniform.inverseTileTextureSize, layer.inverseTileDataTextureSize);

            gl.activeTexture(RenderingContext.TEXTURE0);
            gl.bindTexture(RenderingContext.TEXTURE_2D, layer.spriteTexture);

            gl.activeTexture(RenderingContext.TEXTURE1);
            gl.bindTexture(RenderingContext.TEXTURE_2D, layer.tileDataTexture);
            
            gl.drawArrays(RenderingContext.TRIANGLES, 0, 6);
        }
    }

    /*

    256*8=2048

    8x8 supertiles = 64 supertiles

    of 

    16*16 8*8 pixel tiles = 256 tiles

    total = 64 * 256 = 16k tiles

p.y = index % 8;
p.x = Math.floor(index / 8);

    */
    
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
        // "   if(tile.x == 1.0 && tile.y == 1.0) { discard; }",
        "   if(tile.x == 1.0 && tile.y == 1.0) { ",
        "    discard;", 
        // "    gl_FragColor = vec4(0.0,0.0,0.0,0.0);", 
        "   } else {",
        "   vec2 superSpriteOffset = floor(tile.zw * 256.0) * 256.0;",
        "   vec2 spriteOffset = floor(tile.xy * 256.0) * tileSize;",
        "   vec2 spriteCoord = mod(pixelCoord, tileSize);",

        //Works
        // "   spriteCoord.x = (-1.0+(2.0* 0.0)) * (( 0.0*tileSize) - spriteCoord.x);", //normal  0
        // "   spriteCoord.x = (-1.0+(2.0* 1.0)) * (( 1.0*tileSize) - spriteCoord.x);", //flip   1
        

        "   gl_FragColor = texture2D(sprites, (superSpriteOffset + spriteOffset + spriteCoord) * inverseSpriteTextureSize);",
        "   }",
        "}"
    ];

}