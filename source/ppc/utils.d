module ppc.utils;

public static ubyte[] Combine(ubyte[] to, ubyte[] from) {
	long ol = to.length;
	ubyte[] result = to.dup;
	result.length += from.length;
	for(int i = 0; i < from.length; i++) {
		result[ol+i] = from[i];
	}
	return result;
}