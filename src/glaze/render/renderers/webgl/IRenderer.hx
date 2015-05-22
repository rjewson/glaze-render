
package wgr.renderers.webgl;

import js.html.webgl.RenderingContext;
import wgr.display.Camera;

interface IRenderer 
{
    function Init(gl:RenderingContext,camera:Camera):Void;
    function Resize(width:Int,height:Int):Void;
    function Render(clip:wgr.geom.AABB):Void;
}