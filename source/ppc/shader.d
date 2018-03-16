module ppc.shader;
import ppc;
import ppc.exceptions;

import std.conv;
import std.bitmanip;

public class ShaderFactory : ContentFactory {
	public this() {
		super(TypeId.Shader);
	}

	public override Content Construct(ubyte[] data) {
		return new Shader(data);
	}
}

public enum ShaderType : ubyte {
	SPIRV,
	GLSL,
	PPSL
}

public enum CodeType : ubyte {
	SPIRVFullShader,
	PPSLFullShader,
	Vertex,
	Geometry,
	Fragment
}

public class ShaderCode {
	public CodeType Type;
	public ubyte[] Code;
	public @property string CodeString() { return cast(string)Code; }
	public @property void CodeString(string value) { Code = cast(ubyte[])value; }

	public this(CodeType type) {
		this.Type = type;
		this.Code = [];
	}

	public this(CodeType type, ubyte[] code) {
		this.Type = type;
		this.Code = code;
	}
}

public class Shader : Content {

	public ShaderType Type;
	public ShaderCode[] Code;

	public this(string name) {
		super(TypeId.Shader, name);
	}

	public this(ubyte[] data) {
		super(data);
		this.Type = cast(ShaderType)this.data[0];
		bool done = false;
		int i = 1;
		while (!done) {
			// Set Code Type Header.
			CodeType t = cast(CodeType)this.data[i];
			i++;

			// Set Length Header.
			ubyte[4] len_i = this.data[i..i+4];
			int length = bigEndianToNative!int(len_i);
			i += 4;

			if (length == 0) throw new InvalidHeaderSizeException("Shader [Infinite loading loop!]");

			// Set Shader Code.
			ubyte[] d = this.data[i..i+length];
			i += length;
			Code.length++;
			Code[Code.length-1] = new ShaderCode(t, d);

			//Finish off loading the shader code, if no more data is left.
			if (i+1 >= this.data.length) done = true;
		}
	}

	public void Add(ShaderCode code) {
		this.Code.length++;
		this.Code[this.Code.length-1] = code;
	}

	public override ubyte[] Compile() {
		ubyte[] data = [cast(ubyte)Type];
		foreach(ShaderCode c; Code) {
			
			//Add Type header for shader code.
			data.length += 1;
			ulong s = data.length-1;
			data[s] = cast(ubyte)c.Type;
			s++;

			//Add Size header for shader code.
			data.length += 4;
			int len_i = cast(int)c.Code.length;
			ubyte[] len = nativeToBigEndian(len_i);
			s += 4;

			//Add shader code.
			data.length += c.Code.length;
			for (int i = 0; i < c.Code.length; i++) {
				data[s+i] = c.Code[i];
			}
		}
		return data;
	}
}