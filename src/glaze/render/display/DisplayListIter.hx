
package glaze.render.display;

import glaze.render.display.DisplayObjectContainer;

class DisplayListIter 
{

    var node:DisplayObjectContainer;
    var stack:Array<DisplayObjectContainer>;
    var top:Int;

    public function new(root:DisplayObjectContainer) {
        node = root;
        stack = new Array<DisplayObjectContainer>();
        reset();
    }

    public function reset() {
        stack[0] = node;
        top = 1;
    }

    public inline function hasNext():Bool {
        return top>0;
    }

    public inline function next():DisplayObjectContainer {
        //This is the current node we want to return
        var thisNode = stack[--top];
        //If there is an adjacent node, push it to the stack
        if (thisNode.next!=null)
            stack[top++] = cast thisNode.next; //Big assumption is only DisplayListContainers, which it is for now.
        //If there is a child list, push the head (this will get processed first)
        if (thisNode.head!=null)
            stack[top++] = cast thisNode.head; //Same assumption.  
        //return the result
        return thisNode;
    }

}