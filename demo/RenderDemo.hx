package ;

import glaze.render.display.Camera;
import js.Browser;
import glaze.geom.Vector2;
import glaze.core.GameLoop;

class RenderDemo 
{

    // public static inline var mapData:String = "eJxjZGBgYKQyphaglXnUMnOw+Jfe8UHt8KOWmdT2O7XT/2BJL0PJPHLilFg7R6p51MQAVwMAbQ==";
    public static inline var mapData:String = "eJxjZGBgYKQyphaglXnUMpMe/iXGfHrHB7XDj1pmkut/XGqonQeGSv4YTOZRMz5xmT3SzKMmBgBlKwBx";

    public var loop:GameLoop;

    public var camera:Camera;

    public function new() {
        loop = new GameLoop();
        loop.updateFunc = update;

        camera = new Camera();

        loop.start();

        trace(camera);
    }    

    public function update(delta:Float,now:Int) {
        
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