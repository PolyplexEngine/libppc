module ppc.bundle;
import ppc;
import ppc.exceptions;
import ppc.utils;

import std.conv;
import std.bitmanip;


public class BundleFactory : ContentFactory {
	public this() {
		super(TypeId.Bundle);
	}

	public override Content Construct(ubyte[] data) {
		return new Bundle(data);
	}
}

public class Bundle : Content {

	public Content[string] BundleContents;

	public this(string name) {
		super(TypeId.Bundle, name);
	}

	public this(ubyte[] data) {
		super(data);
		ulong[] d_lookup = [];
		Content[] d_cont = [];

		int ulong_size = ulong.sizeof;

		// Get lookup table size.
		ubyte[ulong.sizeof] s = this.data[0..ulong_size];
		ulong d_lookup_len = bigEndianToNative!ulong(s);

		// Load lookup table.
		for (int i = 0; i < d_lookup_len; i++) {
			d_lookup.length++;
			s = this.data[ulong_size*i..ulong_size];
			d_lookup[d_lookup.length-1] = bigEndianToNative!ulong(s);
		}

		// Iterate through lookup table.
		for(int i = 0; i < d_lookup.length; i++) {
			// Get read-length.
			ulong lookup = d_lookup[i];
			ulong n_lookup = data.length;
			if (i+1 < d_lookup.length) n_lookup = d_lookup[i+1];

			// Read and create content.
			d_cont.length++;
			d_cont[d_cont.length-1] = ContentManager.Load(this.data[lookup..n_lookup]);
		}

		// Move over to storage inside bundle.
		foreach(Content c; d_cont) {
			this.BundleContents[c.Name] = c;
		}
	}

	public void Add(Content cont) {
		BundleContents[cont.Name] = cont;
	}

	public override ubyte[] Compile() {
		ubyte[] d = [];
		ubyte[] d_lookup_b = [];
		ulong[] d_lookup = [];
		ubyte[] d_lookup_t_len = [];

		// Compile components.
		foreach(Content c; BundleContents) {
			
			// Add next position to lookup table.
			d_lookup.length++;
			d_lookup[d_lookup.length-1] = d.length;

			// Compile content and add it to data output.
			d = Combine(d, c.CompileFull());
		}

		// Create lookup table
		foreach(ulong lookup_id; d_lookup) {
			d_lookup_b = Combine(d_lookup_b, nativeToBigEndian(lookup_id));
		}

		// Create lookup table length.
		d_lookup_t_len = nativeToBigEndian(d_lookup_b.length);

		// Combine all and push to output.
		return Combine(Combine(d_lookup_t_len, d_lookup_b), d);
	}
}