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

    public var lastSnap:Vector2;
    public var thisSnap:Vector2;
    public var snapChanged:Bool;

    public var size:Vector2;

	public function new(tileMap:TileMap,layers:Array<Int>) {
		this.tileMap = tileMap;
		this.layers = layers;	

		lastSnap = new Vector2(0,0);
        thisSnap = new Vector2(-1000,-1000);
        snapChanged = false;

        size = new Vector2();

	}

	public function Init(gl:RenderingContext,camera:Camera) {
        sprite = new Sprite();
        sprite.id = "renderTexture";
	}

	public function Resize(width:Int,height:Int) {
		size.setTo(width,height);
        surface = new BaseTexture(tileMap.gl,Std.int(width),Std.int(height));
        texture = new Texture(surface,new Rectangle(0,0,width,height),new glaze.geom.Vector2(0,0));
        sprite.texture = texture;
        sprite.scale.setTo(2,-2);
        sprite.pivot.setTo(width/2,height/2);		
	}

    public function calcSnap(cameraPos:Vector2):Bool {
        lastSnap.copy(thisSnap);

        thisSnap.x = (Math.floor(cameraPos.x / -16) - 1 ) * 16;
        // thisSnap.x*=16;
        // thisSnap.x-=16;
        thisSnap.y = (Math.floor(cameraPos.y / -16) - 1 ) * 16;
        // thisSnap.y*=16;
        // thisSnap.y-=16;

        snapChanged = (lastSnap.x!=thisSnap.x || lastSnap.y!=thisSnap.y);

        return snapChanged;
    }

	public function Render(clip:glaze.geom.AABB2) {
        // if (calcSnap(tileMap.camera.position)) {
        calcSnap(tileMap.camera.position);
        	sprite.position.copy(size);
        	sprite.position.plusEquals(thisSnap);
	        // sprite.position.setTo(416+thisSnap.x,336+thisSnap.y);
    	    surface.drawTo(renderSurface);
        // } 
	}

	public function renderSurface() {
		tileMap.RenderLayers(this);
	}

}