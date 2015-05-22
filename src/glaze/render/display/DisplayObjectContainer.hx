
package glaze.render.display;

import glaze.geom.AABB2;
import glaze.render.display.DisplayObject;

class DisplayObjectContainer extends DisplayObject
{
    public var head:DisplayObject;
    public var tail:DisplayObject;
    public var childCount:Int;

    public var subTreeAABB:AABB2;

    public function new() { 
        super();
        subTreeAABB = new AABB2();
        childCount = 0;
    }

    public function addChild(child:DisplayObject) {
        if (child.parent!=null)
            child.parent.removeChild(child);
        insertEnd(child);
        childAdded(child);
    }   

    public function addChildAt(child:DisplayObject,index:Int) {
        if (index>=childCount) {
            addChild(child);
            return;
        }
        if (index==0) {
            insertBeginning(child);
        } else {
            insertBefore(findChildByIndex(index),child);
        }
        childAdded(child);
    }

    private inline function childAdded(child:DisplayObject) {
        childCount++;
        child.parent = this;
        child.applySlot(function(target:DisplayObject,p:Dynamic){target.stage=cast p;return true;},stage);
        if (stage!=null) 
            stage.dirty = true;
    }

    private function findChildByIndex(index:Int):DisplayObject {
        var child = head;
        var count = 0;
        while (child!=null) {
            if (count++==index)
                return child;
            child = child.next;
        }
        return tail;
    }

    public function removeChild(child:DisplayObject) {
        if (child.parent==this) {
            remove(child);
            childRemoved(child);
        }
    }

    public function removeChildAt(index:Int):DisplayObject {
        var child = findChildByIndex(index);
        trace(child);
        removeChild(child);
        this.debug();
        return child;
    }

    private inline function childRemoved(child:DisplayObject) {
        childCount--;
        if (stage!=null) 
            stage.dirty = true;
        child.parent = null;
        child.applySlot(function(target:DisplayObject,p:Dynamic){target.stage=null;return true;},null);
    }

    public override function updateTransform() {
        //Reset AABB
        aabb.reset();
        super.updateTransform();
        calcExtents();
        subTreeAABB.reset();
        subTreeAABB.addAABB(aabb);
        //Expand AAABB to this DisplayObject -> New function required
        var child = head;
        while (child!=null) {
            child.updateTransform();
            //Inflate this AABB to encapsulate child
            subTreeAABB.addAABB(child.aabb);
            child = child.next;
        }
    }

    public function apply(slot:DisplayObject->Dynamic->Void,p:Dynamic=null) {

    }

    //TODO Probably get rid of this...
    public override function applySlot(slot:DisplayObject->Dynamic->Bool,p:Dynamic=null):Bool {
        if (!super.applySlot(slot,p))
            return false; 
        var child = head;
        while (child!=null) {
            child.applySlot(slot,p);
            child = child.next;
        }
        return true;
    }

    //Linked List Functions
    public inline function insertAfter(node:DisplayObject,newNode:DisplayObject) {
        newNode.prev = node;
        newNode.next = node.next;
        if (node.next==null)
            tail = newNode;
        else
            node.next.prev = newNode;
        node.next = newNode;
    }

    public inline function insertBefore(node:DisplayObject,newNode:DisplayObject) {
        newNode.prev = node.prev;
        newNode.next = node;
        if (node.prev == null)
            head = newNode;
        else
            node.prev.next = newNode;
        node.prev = newNode;
    }

    public inline function insertBeginning(newNode:DisplayObject) {
        if (head == null) {
            head = newNode;
            tail = newNode;
            newNode.prev = null;
            newNode.next = null;
        } else  
            insertBefore(head, newNode);
     }

     public inline function insertEnd(newNode:DisplayObject) {
        if (tail == null)
            insertBeginning(newNode);
        else
            insertAfter(tail, newNode);
     }

    public inline function remove(node:DisplayObject) {
        if (node.prev == null)
            head = node.next;
        else
            node.prev.next = node.next;
        if (node.next == null)
            tail = node.prev;
        else
            node.next.prev = node.prev;
        node.prev = node.next = null;
    }

    public function debug() {
        var child = head;
        while (child!=null) {
            trace(child.id);
            child = child.next;
        }
    }

}