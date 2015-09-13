package glaze.render.display;

import glaze.render.display.DisplayObjectContainer;
import glaze.geom.Vector2;
import glaze.geom.AABB2;

class Camera extends DisplayObjectContainer
{

    public var realPosition:Vector2;
    public var viewportSize:Vector2;
    public var halfViewportSize:Vector2;
    public var viewPortAABB:AABB2;
    public var worldExtentsAABB:AABB2;
    private var cameraExtentsAABB:AABB2;

    public function new() {
        super();
        id = "Camera";
        realPosition = new Vector2();
        viewportSize = new Vector2();
        halfViewportSize = new Vector2();
        viewPortAABB = new AABB2();
        worldExtentsAABB = new AABB2();
    }

    function rf(v:Float) {
        return Math.floor(v);
    }

    public function Focus(x:Float,y:Float) {
        //Need to move the camera container the oposite way to the actual coords
        realPosition.x = x;
        realPosition.y = y;
        //Clamp position inside shrunk camera extents
        cameraExtentsAABB.fitPoint(realPosition);
        position.x = rf(-realPosition.x+halfViewportSize.x);
        position.y = rf(-realPosition.y+halfViewportSize.y);
    }

    public function Resize(width:Int,height:Int) {
        viewportSize.x = width;
        viewportSize.y = height;
        halfViewportSize.x = width/2;
        halfViewportSize.y = height/2;
        viewPortAABB.l = viewPortAABB.t = 0;
        viewPortAABB.r = viewportSize.x;
        viewPortAABB.b = viewportSize.y;
        //Clone the world size, then shrink it around the center by viewport size
        cameraExtentsAABB = worldExtentsAABB.clone();
        cameraExtentsAABB.expand2(width,height);
    }


}