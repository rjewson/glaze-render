
package glaze.render.renderers.webgl;

import js.html.webgl.Program;
import js.html.webgl.RenderingContext;
import js.html.webgl.Shader;

class WebGLShaders 
{

    public static function CompileVertexShader(gl:RenderingContext,shaderSrc:Array<String>):Shader {
        return CompileShader(gl,shaderSrc,RenderingContext.VERTEX_SHADER);
    }

    public static function CompileFragmentShader(gl:RenderingContext,shaderSrc:Array<String>):Shader {
        return CompileShader(gl,shaderSrc,RenderingContext.FRAGMENT_SHADER);
    }

    public static function CompileShader(gl:RenderingContext,shaderSrc:Array<String>,shaderType:Int):Shader {
        var src = shaderSrc.join("\n");
        var shader = gl.createShader(shaderType);
        gl.shaderSource(shader,src);
        gl.compileShader(shader);
        if (!gl.getShaderParameter(shader,RenderingContext.COMPILE_STATUS)) {
            js.Browser.alert(gl.getShaderInfoLog(shader));
            return null;
        }
        return shader;
    }

    public static function CompileProgram(gl:RenderingContext,vertexSrc:Array<String>,fragmentSrc:Array<String>):Program {
        var vertexShader = CompileVertexShader(gl,vertexSrc);
        var fragmentShader = CompileFragmentShader(gl,fragmentSrc);
        var shaderProgram = gl.createProgram();

        gl.attachShader(shaderProgram,vertexShader);
        gl.attachShader(shaderProgram,fragmentShader);
        gl.linkProgram(shaderProgram);

        if (!gl.getProgramParameter(shaderProgram,RenderingContext.LINK_STATUS)) {
            js.Browser.alert("Could not initialize program");
            trace(vertexSrc);
            trace(fragmentSrc);
            trace(gl.getProgramInfoLog(shaderProgram));
        }
        return shaderProgram;
    }

}