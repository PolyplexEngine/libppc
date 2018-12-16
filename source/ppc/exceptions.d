module ppc.exceptions;

public class InvalidFileException : Exception {
	this(string format) {
		super("File was not a(n) <" ~ format ~ "> file");
	}
}

public class InvalidMagicBytesException : Exception {
	this(string format) {
		super("File did not have magic bytes matching the <" ~ format ~ "> file format");
	}
}

public class InvalidHeaderSizeException : Exception {
	this(string origin) {
		super("An invalid sized header was specified when handling <" ~ origin ~ ">, content might be corrupt?");
	}
}