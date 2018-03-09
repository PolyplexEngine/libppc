module ppc.exceptions;

public class InvalidFileFormatException : Exception {
	this() {
		super("Specified file was not a polyplex content file!");
	}
}