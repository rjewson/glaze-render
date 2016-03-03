package glaze.render.renderers.webgl;

import glaze.render.display.Camera;
import glaze.render.renderers.webgl.IRenderer;
import glaze.render.renderers.webgl.TileMap;
import js.html.webgl.RenderingContext;

//TODO: Get rid of this class eventually
//Its only to be able to split the tilemap renderer in the short term

class TileLayerRenderProxy implements IRenderer {

	public var tileMap:TileMap;
	public var layers:Array<Int>;

	public function new(tileMap:TileMap,layers:Array<Int>) {
		this.tileMap = tileMap;
		this.layers = layers;	
	}

	public function Init(gl:RenderingContext,camera:Camera) {
		tileMap.Init(gl,camera);
	}

	public function Resize(width:Int,height:Int) {
		tileMap.Resize(width,height);
	}

	public function Render(clip:glaze.geom.AABB2) {
		tileMap.RenderLayers(clip,layers);
	}

}