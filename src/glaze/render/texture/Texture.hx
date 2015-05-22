
package glaze.render.texture;

import js.html.Float32Array;
import js.html.webgl.RenderingContext;
import js.html.webgl.Texture;
import glaze.geom.Vector2;
import glaze.geom.Rectangle;
import glaze.render.texture.BaseTexture;

class Texture 
{
    public var baseTexture:BaseTexture;
    public var frame:Rectangle;
    public var trim:Vector2;
    public var pivot:Vector2;
    public var noFrame:Bool;
    public var uvs:Float32Array;

    public function new(baseTexture:BaseTexture,frame:Rectangle,pivot:Vector2 = null) {
        noFrame = false;
        this.baseTexture = baseTexture;

        if (frame==null) {
            noFrame = true;
            this.frame = new Rectangle(0,0,1,1);
        } else {
            this.frame = frame;
        }
        this.trim = new Vector2();
        this.pivot = pivot==null ? new Vector2() : pivot;
        this.uvs = new Float32Array(8);
        updateUVS();
    }

    public function updateUVS() {

        var tw = baseTexture.width;
        var th = baseTexture.height;

        uvs[0] = frame.x / tw;
        uvs[1] = frame.y / th;

        uvs[2] = (frame.x + frame.width) / tw;
        uvs[3] = frame.y / th;

        uvs[4] = (frame.x + frame.width) / tw;
        uvs[5] = (frame.y + frame.height) / th;

        uvs[6] = frame.x / tw;
        uvs[7] = (frame.y + frame.height) / th;
    }

}