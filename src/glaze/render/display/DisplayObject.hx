
package glaze.render.display;

import js.html.Float32Array;
import glaze.render.display.DisplayObjectContainer;
import glaze.render.display.Stage;
import glaze.geom.Matrix3;
import glaze.geom.Vector2;
import glaze.geom.AABB2;

class DisplayObject 
{
    public var id:String;
    public var position:Vector2;
    public var scale:Vector2;
    public var pivot:Vector2;
    public var rotation(get,set):Float;
    private var _rotation:Float;
    private var _rotationComponents:Vector2;
    public var alpha:Float;
    public var visible(get,set):Bool;
    private var _visible:Bool;
    public var renderable:Bool;

    public var aabb:AABB2;

    public var parent:DisplayObjectContainer;
    public var stage:Stage;

    public var worldTransform:Float32Array;
    public var worldAlpha:Float;
    public var localTransform:Float32Array;

    public var prev:DisplayObject;
    public var next:DisplayObject;

    public function new() {
        position = new Vector2();
        scale = new Vector2(1,1);
        pivot = new Vector2();
        _rotationComponents = new Vector2();
        rotation = 0;
        alpha = 1;
        visible = true;
        renderable = false;
        aabb = new AABB2();
        parent = null;
        worldTransform = Matrix3.Create();
        localTransform = Matrix3.Create();
    }

    public inline function get_rotation():Float {  
        return _rotation;
    }

    public inline function set_rotation(v:Float):Float {
        _rotation = v;
        _rotationComponents.x = Math.cos(_rotation);
        _rotationComponents.y = Math.sin(_rotation);
        return _rotation;
    }

    public inline function get_visible():Bool {  
        return _visible;
    }

    public inline function set_visible(v:Bool):Bool {
        _visible = v;
        if (stage!=null)
            stage.dirty = true;
        return _visible;
    }
    public function RoundFunction(v:Float):Float {
        // return v;
        // return Math.round(v);
        return Math.round( v * 10) / 10;
    }

    public function updateTransform() {
        //TODO Rounding at the moment...
        //position.x = Math.round(position.x);
        //position.y = Math.round(position.y);

        //JS hack, much faster...
         // var positionx:Int = untyped{(0.5 + position.x) >> 0;};
         // var positiony:Int = untyped{(0.5 + position.y) >> 0;};
        //positionx = cast Math.round( position.x * 10) / 10;
        //positiony = cast Math.round( position.y * 10) / 10;

        // var positionx = position.x;
        // var positiony = position.y;

        var positionx:Int = Math.floor(position.x + 0.5);
        var positiony:Int = Math.floor(position.y + 0.5);

        var sinR = _rotationComponents.y;//Math.sin(rotation);
        var cosR = _rotationComponents.x;//Math.cos(rotation);
        
        localTransform[0] =  cosR * scale.x;
        localTransform[1] = -sinR * scale.y;
        localTransform[3] =  sinR * scale.x;
        localTransform[4] =  cosR * scale.y;

        var px = pivot.x;
        var py = pivot.y;

        var parentTransform = parent.worldTransform;

        var a00 = localTransform[0];
        var a01 = localTransform[1];
        var a02 = positionx - localTransform[0] * px - py * localTransform[1];
        var a10 = localTransform[3];
        var a11 = localTransform[4];
        var a12 = positiony - localTransform[4] * py - px * localTransform[3];
        var b00 = parentTransform[0];
        var b01 = parentTransform[1];
        var b02 = parentTransform[2];
        var b10 = parentTransform[3];
        var b11 = parentTransform[4];
        var b12 = parentTransform[5];

        localTransform[2] = a02;
        localTransform[5] = a12;

        worldTransform[0] = b00 * a00 + b01 * a10;
        worldTransform[1] = b00 * a01 + b01 * a11;
        worldTransform[2] = b00 * a02 + b01 * a12 + b02;

        worldTransform[3] = b10 * a00 + b11 * a10;
        worldTransform[4] = b10 * a01 + b11 * a11;
        worldTransform[5] = b10 * a02 + b11 * a12 + b12;

        worldAlpha = alpha*parent.worldAlpha;

    }

    public function calcExtents() {
        
    }

    //TODO Probably get rid of this...
    public function applySlot(slot:DisplayObject->Dynamic->Bool,p:Dynamic=null):Bool {
        return slot(this,p);    
    }


}