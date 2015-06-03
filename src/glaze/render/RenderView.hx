package;

import glaze.render.display.Stage;
import glaze.render.display.Camera;
import glaze.render.renderer.WebGLRenderer;
import js.html.CanvasElement;

class View {
    
    public var stage:Stage;
    public var camera:Camera;
    public var renderer:WebGLRenderer;
    public var canvasView:CanvasElement;
    public var debugView:CanvasElement;
    //public var debugRenderer:CanvasDebugView;

    public function new(canvasID:String,debugID:String,width:Int,height:Int,camera:Camera,debug:Bool) {
        this.stage = new Stage();
        this.camera = camera;
        this.stage.addChild(camera);

        this.canvasView = cast(Browser.document.getElementById(canvasID),CanvasElement);
        this.renderer = new WebGLRenderer(stage,camera,canvasView,width,height);

        this.debugView = cast(Browser.document.getElementById(debugID),CanvasElement);
        //this.debugRenderer = new CanvasDebugView(debugView,camera,width,height);

        camera.Resize(renderer.width,renderer.height);
    }
}