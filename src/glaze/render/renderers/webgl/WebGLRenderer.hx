 
package glaze.render.renderers.webgl;

import js.html.CanvasElement;
import js.html.Event;
import js.html.webgl.ContextAttributes;
import js.html.webgl.Program;
import js.html.webgl.RenderingContext;
import glaze.render.display.Camera;
import glaze.render.display.Stage;
import glaze.geom.Vector2;
import glaze.geom.AABB2;
import glaze.render.renderers.webgl.IRenderer;
import glaze.render.renderers.webgl.ShaderWrapper;
import glaze.render.renderers.webgl.SpriteRenderer;
import glaze.render.renderers.webgl.WebGLBatch;
import glaze.render.renderers.webgl.WebGLShaders;

class WebGLRenderer 
{

    public var stage:Stage;
    public var camera:Camera;
    public var view:CanvasElement;
    public var width:Int;
    public var height:Int;

    public var gl:RenderingContext;
    public var contextAttributes:ContextAttributes;

    private var contextLost:Bool; 

    public var renderers:Array<IRenderer>;

    public function new(stage:Stage,camera:Camera,view:CanvasElement,width:Int = 800,height:Int=600,transparent:Bool=false,antialias:Bool=false) {
        this.stage = stage;
        this.camera = camera;
        this.view = view;
        this.contextLost = false;

        contextAttributes = {};
        contextAttributes.alpha = transparent;
        contextAttributes.antialias = antialias;
        contextAttributes.premultipliedAlpha = false;
        contextAttributes.stencil = false;

        renderers = new Array<IRenderer>();

        InitalizeWebGlContext();
        Resize(width,height);
    }

    public function InitalizeWebGlContext() {
        view.addEventListener('webglcontextlost',onContextLost,false);
        view.addEventListener('webglcontextrestored',onContextRestored,false); 
        gl = view.getContextWebGL( contextAttributes );

        gl.disable(RenderingContext.DEPTH_TEST);
        gl.disable(RenderingContext.CULL_FACE);
        gl.enable(RenderingContext.BLEND);
        gl.colorMask(true,true,true,contextAttributes.alpha);
        gl.clearColor(0,0,0,1);

        if (!gl.getExtension('OES_texture_float')) 
            trace('New browser time: Float textures not supported');
    }
  
    public function Resize(width:Int,height:Int) {
        this.width = width;
        this.height = height;
        view.width = width;
        view.height = height;
        gl.viewport(0,0,width,height);
    }

    public function AddRenderer(renderer:IRenderer) {
        renderer.Init(gl,camera);
        renderer.Resize(width,height);
        renderers.push(renderer);
    }

    public function Render(clip:AABB2) {
        if (contextLost) 
            return;
        stage.updateTransform();
        stage.PreRender();
        //gl.viewport(0,0,width,height);
        // gl.colorMask(true,true,true,contextAttributes.alpha);
        // gl.bindFramebuffer(RenderingContext.FRAMEBUFFER,null);
        //gl.clear(RenderingContext.COLOR_BUFFER_BIT);
        //gl.blendFunc(RenderingContext.ONE,RenderingContext.ONE_MINUS_SRC_ALPHA);
        for (renderer in renderers)
            renderer.Render(clip);
    }

    private function onContextLost(event:Event) {
        contextLost = true;
        trace("webGL Context Lost");
    }

    private function onContextRestored(event:Event) {
        contextLost = false;
        trace("webGL Context Restored");
    }

}