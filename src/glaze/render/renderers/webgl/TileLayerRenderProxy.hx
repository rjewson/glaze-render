package glaze.render.renderers.webgl;

import glaze.geom.Rectangle;
import glaze.geom.Vector2;
import glaze.render.display.Camera;
import glaze.render.display.Sprite;
import glaze.render.frame.Frame;
import glaze.render.renderers.webgl.IRenderer;
import glaze.render.renderers.webgl.TileMap;
import glaze.render.texture.BaseTexture;
import glaze.render.texture.Texture;
import js.html.webgl.RenderingContext;

//TODO: Get rid of this class eventually
//Its only to be able to split the tilemap renderer in the short term

class TileLayerRenderProxy implements IRenderer {

	public var tileMap:TileMap;
	public var layers:Array<Int>;

	public var surface:BaseTexture;
	public var texture:Texture;
	public var sprite:Sprite;

    var lastSnap:Vector2;
    var thisSnap:Vector2;
    var snapChanged:Bool;


	public function new(tileMap:TileMap,layers:Array<Int>) {
		this.tileMap = tileMap;
		this.layers = layers;	

		lastSnap = new Vector2(0,0);
        thisSnap = new Vector2(-1000,-1000);
        snapChanged = false;

	}

	public function Init(gl:RenderingContext,camera:Camera) {
		tileMap.Init(gl,camera);
        surface = new BaseTexture(gl,Std.int(800/2),Std.int(640/2));
        texture = new Texture(surface,new Rectangle(0,0,800/2,640/2),new glaze.geom.Vector2(0,0));
        sprite = new Sprite();
        sprite.id = "renderTexture";
        sprite.texture = texture;
        sprite.scale.setTo(2,-2);
        sprite.pivot.setTo(400/2,320/2);
	}

	public function Resize(width:Int,height:Int) {
		tileMap.Resize(width,height);
	}

    public function calcSnap(cameraPos:Vector2):Bool {
        lastSnap.copy(thisSnap);

        thisSnap.x = Math.floor(cameraPos.x / -16);
        thisSnap.x*=16;
        thisSnap.x-=16;
        thisSnap.y = Math.floor(cameraPos.y / -16);
        thisSnap.y*=16;
        thisSnap.y-=16;

        snapChanged = (lastSnap.x!=thisSnap.x || lastSnap.y!=thisSnap.y);

        return snapChanged;
    }

	public function Render(clip:glaze.geom.AABB2) {
        if (calcSnap(tileMap.camera.position)) {
	        sprite.position.setTo(400+thisSnap.x,320+thisSnap.y);
    	    surface.drawTo(renderSurface);
        } 
	}

	public function renderSurface() {
		tileMap.RenderLayers(null,layers,thisSnap);
	}

}