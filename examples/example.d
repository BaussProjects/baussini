module main;

import baussini;
import std.stdio : writefln, readln;

void main() {
	string fileName = "test.ini";
	// Thread-safe instance, for a non thread-safe instance replace "true" with "false"
	auto ini = new IniFile!(true)(fileName);
	// Use open() for reading and close() for write. Both can be combined ...
	if (!ini.exists()) {
		ini.addSection("Root");
		// Write way 1
		ini.write!string("Root", "StringValue1", "Hello World!");
		// Write way 2
		ini.getSection("Root").write!int("IntValue1", 9001);
		// Write way 3
		ini.getSection("Root")
			.write!string("StringValue2", "Hello Universe!")
			.write!int("IntValue2", 1000000);
		ini.close();
	}
	else {
		ini.open();
		// Read way 1
		string stringValue1 = ini.read!string("Root", "StringValue1");
		// Read way 2
		int intValue1 = ini.getSection("Root").read!int("IntValue1");
		// Read way 3
		string stringValue2;
		int intValue2;
		ini.getSection("Root")
			.read!string("StringValue2", stringValue2)
			.read!int("IntValue2", intValue2);
		
		writefln("%s is %s", "stringValue1", stringValue1);
		writefln("%s is %s", "intValue1", intValue1);
		writefln("%s is %s", "stringValue2", stringValue2);
		writefln("%s is %s", "intValue2", intValue2);
		readln();
	}
}
