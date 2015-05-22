
package wgr.renderers.canvas;

import js.html.CanvasElement;
import js.html.CanvasRenderingContext2D;
import wgr.display.Camera;

class CanvasDebugView 
{
    public var view:CanvasElement;
    public var ctx:CanvasRenderingContext2D;
    public var camera:Camera;
    public var width:Int;
    public var height:Int;

    public function new(view:CanvasElement,camera:Camera,width:Int = 800,height:Int=600) {
        this.view = view;
        this.camera = camera;
        ctx = view.getContext2d();
        Resize(width,height);
    }

    public function Resize(width:Int,height:Int) {
        this.width = width;
        this.height = height;
        view.width = width;
        view.height = height;
    }

    public function Clear() {
        ctx.setTransform(1, 0, 0, 1, 0, 0);
        ctx.clearRect(0, 0, width, height);
        ctx.strokeStyle = "rgba(0,255,0,1)";
        ctx.translate(camera.position.x,camera.position.y);
    }

    public function DrawRect(x:Float,y:Float,w:Float,h:Float) {
        ctx.strokeRect(x,y,w,h);
    }

    public function DrawAABB(aabb:wgr.geom.AABB) {
        ctx.strokeRect(aabb.l,aabb.t,aabb.width,aabb.height);
    }

    public function DrawPhysicsAABB(aabb:physics.geometry.AABB) {
        ctx.beginPath();
        ctx.moveTo(aabb.l,aabb.t);
        ctx.lineTo(aabb.r,aabb.t);
        ctx.moveTo(aabb.r,aabb.b);
        ctx.lineTo(aabb.l,aabb.b);
        ctx.stroke();    
    }

    public function DrawCross(x:Float,y:Float,l:Float) {
        ctx.beginPath();
        ctx.moveTo(x-l,y);
        ctx.lineTo(x+l,y);
        ctx.moveTo(x,y-l);
        ctx.lineTo(x,y+l);
        ctx.stroke();
    }


}