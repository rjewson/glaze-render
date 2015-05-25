package ;

import glaze.ds.TypedArray2D;
import glaze.render.display.Camera;
import glaze.render.display.Sprite;
import glaze.render.display.Stage;
import glaze.render.renderers.webgl.SpriteRenderer;
import glaze.render.renderers.webgl.TileMap;
import glaze.render.renderers.webgl.WebGLRenderer;
import glaze.render.texture.TextureManager;
import glaze.tmx.TmxMap;
import glaze.util.AssetLoader;
import js.html.CanvasElement;
import js.Browser;
import glaze.geom.Vector2;
import glaze.core.GameLoop;

class RenderDemo 
{

    public static inline var MAP_DATA:String = "data/testMap.tmx";
    public static inline var TEXTURE_CONFIG:String = "data/sprites.json";
    public static inline var TEXTURE_DATA:String = "data/sprites.png";

    public static inline var TILE_SPRITE_SHEET:String = "data/spelunky-tiles.png";
    public static inline var TILE_MAP_DATA_1:String = "data/spelunky0.png";
    public static inline var TILE_MAP_DATA_2:String = "data/spelunky1.png";


    // public static inline var mapData:String = "eJxjZGBgYKQyphaglXnUMnOw+Jfe8UHt8KOWmdT2O7XT/2BJL0PJPHLilFg7R6p51MQAVwMAbQ==";
    public static inline var mapData:String = "eJxjZGBgYKQyphaglXnUMpMe/iXGfHrHB7XDj1pmkut/XGqonQeGSv4YTOZRMz5xmT3SzKMmBgBlKwBx";

    public var loop:GameLoop;

    public var stage:Stage;
    public var camera:Camera;
    public var renderer:WebGLRenderer;
    public var canvasView:CanvasElement;
    public var debugView:CanvasElement;
    //public var debugRenderer:CanvasDebugView;

    public var tm:TextureManager;

    public var assets:AssetLoader;

    public var spriteRender:SpriteRenderer;

    public var character:Sprite;

    public var tmxMap:TmxMap; 

    public function new() {
        loop = new GameLoop();
        loop.updateFunc = update;

        loadAssets([MAP_DATA,TEXTURE_CONFIG,TEXTURE_DATA,TILE_SPRITE_SHEET,TILE_MAP_DATA_1,TILE_MAP_DATA_2]);
    }    

    public function loadAssets(assetList:Array<String>) {
        assets = new AssetLoader();
        assets.loaded.add(setup);
        assets.SetImagesToLoad(assetList);
        assets.Load();
    }

    public function setup(){
        
        stage = new Stage();

        camera = new Camera();

        stage.addChild(camera);

        canvasView = cast(Browser.document.getElementById("view"),CanvasElement);
        renderer = new WebGLRenderer(stage,camera,canvasView,800,600);

        // this.debugView = cast(Browser.document.getElementById("viewDebug"),CanvasElement);
        // this.debugRenderer = new CanvasDebugView(debugView,camera,width,height);

        camera.Resize(renderer.width,renderer.height);

        tm  = new TextureManager(renderer.gl);
        tm.AddTexture(TEXTURE_DATA, assets.assets.get(TEXTURE_DATA) );
        tm.ParseTexturePackerJSON( assets.assets.get(TEXTURE_CONFIG) , TEXTURE_DATA );

        tmxMap = new TmxMap(assets.assets.get(MAP_DATA));
        tmxMap.tilesets[0].set_image(assets.assets.get(TILE_SPRITE_SHEET));

        //var mapData = glaze.util.tmx.TmxLayer.layerToCoordTexture(tmxMap.getLayer("Tile Layer 1"));

        var mapData:TypedArray2D = glaze.tmx.TmxLayer.LayerToCoordTexture(tmxMap.getLayer("Tile Layer 1"));

        var tileMap = new TileMap();
        renderer.AddRenderer(tileMap);
        tileMap.SetSpriteSheet(assets.assets.get(TILE_SPRITE_SHEET));
        tileMap.SetTileLayerFromData(mapData,"base",1,1);
        tileMap.SetTileLayer(assets.assets.get(TILE_MAP_DATA_2),"bg",0.6,0.6);
        tileMap.tileSize = 16;
        tileMap.TileScale(2);

        spriteRender = new SpriteRenderer();
        spriteRender.AddStage(stage);
        renderer.AddRenderer(spriteRender);

        character = createSprite("character","character1.png");
        stage.addChild(character);
        character.position.setTo(100,100);
        
        // trace(tmxMap);

    }

    public function update(delta:Float,now:Int) {
        renderer.Render(camera.viewPortAABB);
    }

    private function createSprite(id:String,tid:String) {
        var s = new Sprite();
        s.id = id;
        s.texture = tm.textures.get(tid);
        s.position.x = 0;
        s.position.y = 0;
        s.pivot.x = s.texture.frame.width * s.texture.pivot.x;
        s.pivot.y = s.texture.frame.height * s.texture.pivot.y;
        return s;
    }

    public static function main() {
        var demo = new RenderDemo();
        Browser.document.getElementById("stopbutton").addEventListener("click",function(event){
            demo.loop.stop();
        });
        Browser.document.getElementById("startbutton").addEventListener("click",function(event){
            demo.loop.start();
        });
    }   

}