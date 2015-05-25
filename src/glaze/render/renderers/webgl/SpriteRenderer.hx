
package glaze.render.renderers.webgl;

import js.html.webgl.RenderingContext;
import glaze.render.display.Camera;
import glaze.render.display.Stage;
import glaze.geom.Vector2;
import glaze.geom.AABB2;
import glaze.render.renderers.webgl.IRenderer;
import glaze.render.renderers.webgl.ShaderWrapper;

class SpriteRenderer implements IRenderer
{

    public var gl:RenderingContext;
    public var stage:Stage;
    public var camera:Camera;

    public var projection:Vector2;

    public var spriteShader:ShaderWrapper;
    
    public var spriteBatch:WebGLBatch;        

    public function new() {
    }

    public function Init(gl:RenderingContext,camera:Camera) {
        this.gl = gl;
        this.camera = camera;
        projection = new Vector2();
        spriteShader = new ShaderWrapper(gl, WebGLShaders.CompileProgram(gl,SPRITE_VERTEX_SHADER,SPRITE_FRAGMENT_SHADER));
        spriteBatch = new WebGLBatch(gl);
        spriteBatch.ResizeBatch(1000);
    }

    public function Resize(width:Int,height:Int) {
        projection.x = width/2;
        projection.y = height/2;
    }

    public function AddStage(stage:Stage) {
        this.stage = stage;
    }

    public function Render(clip:AABB2) {
        gl.useProgram(spriteShader.program);
        gl.enableVertexAttribArray(untyped spriteShader.attribute.aVertexPosition);
        gl.enableVertexAttribArray(untyped spriteShader.attribute.aTextureCoord);
        gl.enableVertexAttribArray(untyped spriteShader.attribute.aColor);
        gl.vertexAttribPointer(untyped spriteShader.attribute.aVertexPosition,2,RenderingContext.FLOAT,false,20,0);
        gl.vertexAttribPointer(untyped spriteShader.attribute.aTextureCoord,2,RenderingContext.FLOAT,false,20,8);
        gl.vertexAttribPointer(untyped spriteShader.attribute.aColor,1,RenderingContext.FLOAT,false,20,16);         
        gl.uniform2f(untyped spriteShader.uniform.projectionVector,projection.x,projection.y);            
        spriteBatch.Render(spriteShader,stage,camera.viewPortAABB);
    }

    public static var SPRITE_VERTEX_SHADER:Array<String> = [
        "precision mediump float;",
        "attribute vec2 aVertexPosition;",
        "attribute vec2 aTextureCoord;",
        "attribute float aColor;",
        "uniform vec2 projectionVector;",
        "varying vec2 vTextureCoord;",
        "varying float vColor;",
        "void main(void) {",
            "gl_Position = vec4( aVertexPosition.x / projectionVector.x -1.0, aVertexPosition.y / -projectionVector.y + 1.0 , 0.0, 1.0);",
            "vTextureCoord = aTextureCoord;",
            "vColor = aColor;",
        "}"
    ];

    public static var SPRITE_FRAGMENT_SHADER:Array<String> = [
        "precision mediump float;",
        "varying vec2 vTextureCoord;",
        "varying float vColor;",
        "uniform sampler2D uSampler;",
        "void main(void) {",
            "gl_FragColor = texture2D(uSampler,vTextureCoord) * vColor;",
        "}"
    ];


}