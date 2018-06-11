module ppc.exceptions;

public class InvalidFileFormatException : Exception {
	this() {
		super("Specified file was not a polyplex content file!");
	}
}

public class InvalidHeaderSizeException : Exception {
	this(string origin) {
		super("An invalid sized header was specified when handling " ~ origin ~ ", content might be corrupt?");
	}
}