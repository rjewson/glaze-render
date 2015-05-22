
package glaze.render.display;

import glaze.render.display.DisplayObject;
import glaze.render.display.DisplayObjectContainer;
import glaze.render.display.Sprite;

class Stage extends DisplayObjectContainer
{

    public var renderHead:Sprite;
    public var renderTail:Sprite;
    public var renderCount:Int;
    public var dirty:Bool;

    public function new() {
        super();
        id = "Stage";
        worldAlpha = alpha;
        stage = this;
    }

    public override function updateTransform() { 
        var child = head;
        while (child!=null) {
            child.updateTransform();
            child = child.next;
        }
    }

    public function PreRender() {
        if (dirty==true) {
            Flatten();
            dirty=false;
        }
    }

    /*
     *   Depth-first Pre-order traversal of tree
     */
    public function Flatten() {
        //trace("Flatten");
        renderHead = null;
        renderTail = null;
        renderCount = 0;
        //Traverse(this);
    }

    public function Traverse(node:DisplayObject) {
        //This node not visible? Snip it all off...
        if (node.visible==false)
            return;
        //Is this a Sprite? If so put it in the list
        if (Std.is(node, Sprite)) {
            if (renderHead==null) {
                renderHead = cast node;
                renderHead.prevSprite = renderHead.nextSprite = null;
            } else {
                var sprite:Sprite = cast node;
                sprite.prevSprite = sprite.nextSprite = null;
                if (renderTail==null) {
                    renderTail = sprite;
                    renderHead.nextSprite = renderTail;
                    renderTail.prevSprite = renderHead;
                } else {
                    renderTail.nextSprite = sprite;
                    sprite.prevSprite = renderTail;
                    renderTail = sprite;                    
                }
            }
            renderCount++;
        }
        //Parse the other children
        if (Std.is(node, DisplayObjectContainer)) {
            var doc:DisplayObjectContainer = cast node;
            var child = doc.head;
            while (child!=null) {
                Traverse(child);
                child = child.next;
            }
        }
    }

}