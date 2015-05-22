
package glaze.render.display;

import js.html.Float32Array;
import glaze.render.display.DisplayObjectContainer;
import glaze.geom.Vector2;
import glaze.render.texture.Texture;

class Sprite extends DisplayObjectContainer
{

    public var anchor:Vector2;
    public var texture:Texture;
    public var blendMode:Int;
    // private var width:Float;
    // private var height:Float;

    public var prevSprite:Sprite;
    public var nextSprite:Sprite;

    public var transformedVerts:Float32Array;

    public function new() {
        super();
        renderable = true;
        anchor = new Vector2();
        transformedVerts = new Float32Array(8);
    }

    public override function calcExtents() {
        var width = texture.frame.width;
        var height = texture.frame.height;

        var aX = anchor.x;
        var aY = anchor.y;
        var w0 = width * (1-aX);
        var w1 = width * -aX;

        var h0 = height * (1-aY);
        var h1 = height * -aY;

        var a = worldTransform[0];
        var b = worldTransform[3];
        var c = worldTransform[1];
        var d = worldTransform[4];
        var tx = worldTransform[2];
        var ty = worldTransform[5];

        transformedVerts[0] = a * w1 + c * h1 + tx; 
        transformedVerts[1] = d * h1 + b * w1 + ty;

        transformedVerts[2] = a * w0 + c * h1 + tx; 
        transformedVerts[3] = d * h1 + b * w0 + ty; 

        transformedVerts[4] = a * w0 + c * h0 + tx; 
        transformedVerts[5] = d * h0 + b * w0 + ty; 

        transformedVerts[6] =  a * w1 + c * h0 + tx; 
        transformedVerts[7] =  d * h0 + b * w1 + ty;

        for (i in 0...4) { 
            aabb.addPoint(transformedVerts[i*2],transformedVerts[(i*2)+1]);
        }
    }

}