
package glaze.render.renderers.webgl;

import js.html.webgl.RenderingContext;
import glaze.render.display.Camera;

interface IRenderer 
{
    function Init(gl:RenderingContext,camera:Camera):Void;
    function Resize(width:Int,height:Int):Void;
    function Render(clip:glaze.geom.AABB2):Void;
}