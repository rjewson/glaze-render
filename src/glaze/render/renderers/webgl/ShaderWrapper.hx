
package wgr.renderers.webgl;

import js.html.webgl.Program;
import js.html.webgl.RenderingContext;

class ShaderWrapper 
{

    public var program:Program;
    public var attribute:Dynamic<String>;
    public var uniform:Dynamic<String>;

    public function new(gl:RenderingContext,program:Program) {
        this.program = program;
        gl.useProgram(this.program);
        attribute = cast {};
        uniform = cast {};
        untyped { 
            var cnt = gl.getProgramParameter(program,RenderingContext.ACTIVE_ATTRIBUTES);
            var i = 0;            
            while (i<cnt){
                var attrib = gl.getActiveAttrib(program,i);
                attribute[attrib.name] = gl.getAttribLocation(program,attrib.name);
                i++;
            }

            cnt = gl.getProgramParameter(program,RenderingContext.ACTIVE_UNIFORMS);
            i=0;
            while (i<cnt){
                var attrib = gl.getActiveUniform(program,i);
                uniform[attrib.name] = gl.getUniformLocation(program,attrib.name);
                i++;
            }
        }
    }

}