/*
*	baussini.d provides a thread-safe by choice inifile wrapper.
*	It supports template writing/reading for values.
*	Please view example.d for an example.
*/
module baussini;

// Imports ...
import std.conv : to;
import std.string : format;
import std.array : replace, split, join;
import std.algorithm : canFind, startsWith, endsWith, stripLeft, stripRight;
import std.traits : isIntegral, isFloatingPoint;

import std.file;
// Aliasing write, read and exists from std.file to avoid name conflicts.
alias fwrite = std.file.write;
alias fread = std.file.readText;
alias fexists = std.file.exists;

/**
*	An inifile exception.
*/
public class IniException : Throwable {
	/**
	*	Creates a new instance of IniException.
	*	Params:
	*		msg =	The message of the exception.
	*/
	this(string msg) {
		super(msg);
	}
}

/**
*	std.traits doesn't have isArithmetic.
*/
private deprecated("isArithmetic is deprecated. write/read supports all types std.conv.to supports.") enum bool isArithmetic(T) =
	isIntegral!T || isFloatingPoint!T;

/**
*	An inifile section wrapper.
*/
class IniSection(bool sync) {
private:
	/**
	*	The parent inifile.
	*/
	IniFile!(sync) m_parent;
	/**
	*	The section name.
	*/
	string m_name;
	/**
	*	The section entries.
	*/
	string[string] m_entries;
	
	/**
	*	Gets the file-writable string
	*	Returns: A string compatible with an inifile.
	*/
	string getWritable() {
		string[] s = [format("[%s]", m_name)];
		foreach (key, value; m_entries) {
			s ~= format("%s=%s", key, value);
		}
		return join(s, "\r\n");
	}
	
	/**
	*	Gets a string value.
	*	Params:
	*		key =			The key to get.
	*		defaultValue =	(lazy) The default value.
	*	Returns: The value of the key if found, defaultValue otherwise.
	*/
	string getValue(string key, lazy string defaultValue) {
		static if (sync) {
			synchronized {
				auto val = m_entries.get(key, defaultValue);
				return val;
			}
		}
		else {
			auto val = m_entries.get(key, defaultValue);
			return val;
		}
	}
	
	/**
	*	Closes the section and clears all entries.
	*/
	void close() {
		m_entries = null;
	}
public:
	/**
	*	Creates a new instance of IniSection.
	*	Params:
	*		name =		The name of the section.
	*		parent =	The parent inifile.
	*/
	this(string name, IniFile!(sync) parent) {
		m_name = name;
		m_parent = parent;
	}
	
	/**
	*	Reads a value from the section.
	*	Params:
	*		key =			The key to read.
	*		defaultValue =	(lazy) The default value.
	*	Returns: The value if found, defaultValue otherwise.
	*/
	auto read(T)(string key, lazy string defaultValue) {
		static if (sync) {
			synchronized {
				auto val = getValue(key, defaultValue);
				return to!T(val);
			}
		}
		else {
			auto val = getValue(key, defaultValue);
			return to!T(val);
		}
	}
	
	/**
	*	Reads a value from the section.
	*	Params:
	*		key =			The key to read.
	*		defaultValue =	(lazy) The default value.
	*		value =			(out) The value if found, defaultValue otherwise.
	*	Returns: The section.
	*/	
	auto read(T)(string key, lazy string defaultValue, out T value) {
		static if (sync) {
			synchronized {
				auto val = getValue(key, defaultValue);
				value = to!T(val);
				return this;
			}
		}
		else {
			auto val = getValue(key, defaultValue);
			value = to!T(val);
			return this;
		}
	}
	
	/**
	*	Reads a value from the section.
	*	Params:
	*		key =	The key to read.
	*	Throws: IniException if the key wasn't found or if the value is empty.
	*	Returns: The value if found.
	*/	
	auto read(T)(string key) {
		static if (sync) {
			synchronized {
				if(!hasKey(key))
					throw new IniException(format("%s does not exist in the section.", key));
				return to!T(getValue(key, ""));
			}
		}
		else {
			if(!hasKey(key))
				throw new IniException(format("%s does not exist in the section.", key));
			return to!T(getValue(key, ""));
		}
	}
	
	/**
	*	Reads a value from the section.
	*	Params:
	*		key =	The key to read.
	*		value =	The value if found.
	*	Throws: IniException if the key wasn't found or if the value is empty.
	*	Returns: The section.
	*/
	auto read(T)(string key, out T value) {
		static if (sync) {
			synchronized {
				if(!hasKey(key))
					throw new IniException(format("%s does not exist in the section.", key));
				value = to!T(getValue(key, ""));
				return this;
			}
		}
		else {
			if(!hasKey(key))
				throw new IniException(format("%s does not exist in the section.", key));
			value = to!T(getValue(key, ""));
			return this;
		}
	}
	
	/**
	*	Writes an entry to the section.
	*	Params:
	*		key =	The key of the entry.
	*		value =	The value of the entry.
	*	Returns: The section.
	*/
	auto write(T)(string key, T value) {
		static if (sync) {
			synchronized {
				m_entries[key] = to!string(value);
				m_parent.m_changed = true;
				return this;
			}
		}
		else {
			m_entries[key] = to!string(value);
			m_parent.m_changed = true;
			return this;
		}
	}
	
	/**
	*	Checks whether the section has a key or not.
	*	Params:
	*		key =	The key to check for.
	*	Returns: True if the key exists, false otherwise.
	*/
	bool hasKey(string key) {
		static if (sync) {
			synchronized {
				return (key in m_entries) !is null;
			}
		}
		else {
			return (key in m_entries) !is null;
		}
	}
	
	@property {
		/**
		*	Gets the name of the section.
		*/
		string name() {
			static if (sync) {
				synchronized {
					return m_name;
				}
			}
			else {
				return m_name;
			}
		}
		
		/**
		*	Gets the keys of the section.
		*/
		string[] keys() {
			static if (sync) {
				synchronized {
					return m_entries.keys;
				}
			}
			else {
				return m_entries.keys;
			}
		}

		/**
		*	Gets the values of the section.
		*/
		string[] values() {
			static if (sync) {
				synchronized {
					return m_entries.values;
				}
			}
			else {
				return m_entries.values;
			}	
		}
		
		/**
		*	Gets the parental inifile.
		*/
		IniFile!(sync) parent() {
			static if (sync) {
				synchronized {
					return m_parent;
				}
			}
			else {
				return m_parent;
			}
		}
	}
}

/**
*	An inifile wrapper.
*/
class IniFile(bool sync) {
private:
	/**
	*	The sections of the inifile.
	*/
	IniSection!(sync)[string] m_sections;
	/**
	*	The file name of the inifile.
	*/
	string m_fileName;
	/**
	*	A boolean determining whether the inifile has got any changes.
	*/
	bool m_changed;
	
	/**
	*	Parses the inifile from text.
	*	Params:
	*		text =	The text to parse.
	*/
	void parseFromText(string text) {
		text = replace(text, "\r", "");
		scope auto lines = split(text, "\n");
		IniSection!(sync) currentSection;
		foreach (sline; lines) {
			auto line = stripLeft(sline, ' ');
			line = stripLeft(sline, '\t');
			
			if (startsWith(line, ";"))
					continue;
			
			if (line && line.length) {
				if (startsWith(line, "[") && endsWith(line, "]")) {
					currentSection = new IniSection!(sync)(line[1 .. $-1], this);
					m_sections[currentSection.name] = currentSection;
				}
				else if (canFind(line, "=") && currentSection) {
					auto data = split(line, "=");
					if (data.length == 2) {
						auto key = stripRight(data[0], ' ');
						key = stripLeft(key, ' ');
						auto value = split(data[1], ";")[0];
						value = stripRight(value, ' ');
						value = stripLeft(value, ' ');
						currentSection.write(key, value);
					}
				}
			}
		}
	}
	
	/**
	*	Parses the inifile to text.
	*	Returns: A string representing the text.
	*/
	string parseToText() {
		string s;
		foreach (section; m_sections.values) {
			s ~= section.getWritable() ~ "\r\n\r\n";
		}
		if (s && s.length >= 2) {
			s.length -= 1; // EOF has to be 1 one new line only.
			return s;
		}
		else
			return "";
	}
public:
	/**
	*	Creates a new instance of IniFile.
	*	Params:
	*		fileName =	The file name of the inifile.
	*/
	this(string fileName) {
		m_fileName = fileName;
		m_changed = false;
	}
	
	/**
	*	Checks whether the inifile exists or not.
	*	Returns: True if the file exists, false otherwise.
	*/
	bool exists() {
		static if (sync) {
			synchronized {
				return fexists(m_fileName);
			}
		}
		else {
			return fexists(m_fileName);
		}
	}
	
	/**
	*	Opens the inifile and parses its text.
	*/
	void open() {
		static if (sync) {
			synchronized {
				parseFromText(
					fread(m_fileName)
				);
			}
		}
		else {
			parseFromText(
				fread(m_fileName)
			);
		}
	}
	
	/**
	*	Closes the inifile and writes its text if any changes has occured.
	*/
	void close() {
		static if (sync) {
			synchronized {
				if (!m_changed)
					return;
				
				fwrite(m_fileName, parseToText());
				foreach (section; m_sections.values)
					section.close();
				m_sections = null;
			}
		}
		else {
			if (!m_changed)
				return;
				
			fwrite(m_fileName, parseToText());
			foreach (section; m_sections.values)
				section.close();
			m_sections = null;
		}
	}
	
	/**
	*	Checks whether the inifile has a specific section.
	*	Params:
	*		section =	The section to check for existence.
	*	Returns: True if the section exists, false otherwise.
	*/
	bool hasSection(string section) {
		static if (sync) {
			synchronized {
				return m_sections.get(section, null) !is null;
			}
		}
		else {
			return m_sections.get(section, null) !is null;
		}
	}
	
	/**
	*	Gets a specific section of the inifile.
	*	Params:
	*		section = The section to get.
	*	Returns: The section.
	*/
	auto getSection(string section) {
		static if (sync) {
			synchronized {
				if(!hasSection(section))
					throw new IniException(format("%s is not an existing section.", section));
				return m_sections[section];
			}
		}
		else {
			if(!hasSection(section))
				throw new IniException(format("%s is not an existing section.", section));
			return m_sections[section];
		}
	}
	
	/**
	*	Adds a new section to the inifile.
	*	Params:
	*		section = The section to add.
	*/
	void addSection(string section) {
		static if (sync) {
			synchronized {
				m_sections[section] = new IniSection!(sync)(section, this);
			}
		}
		else {
			m_sections[section] = new IniSection!(sync)(section, this);
		}
	}
	
	/**
	*	Reads an entry from the inifile.
	*	Params:
	*		section =	The section to read from.
	*		key =		The key of the entry to read.
	*	Returns: The value read.
	*/
	auto read(T)(string section, string key) {
		static if (sync) {
			synchronized {
				if(!hasSection(section))
					throw new IniException(format("%s is not an existing section.", section));
				return m_sections[section].read!T(key);
			}
		}
		else {
			if(!hasSection(section))
				throw new IniException(format("%s is not an existing section.", section));
			return m_sections[section].read!T(key);
		}
	}
	
	/**
	*	Writes an entry to the inifile.
	*	Params:
	*		section =	The section to write the entry to.
	*		key =		The key of the entry.
	*		value =		The value of the entry.
	*/
	void write(T)(string section, string key, T value) {
		static if (sync) {
			synchronized {
				if(!hasSection(section))
					throw new IniException(format("%s is not an existing section.", section));
				m_sections[section].write!T(key, value);
			}
		}
		else {
			if(!hasSection(section))
				throw new IniException(format("%s is not an existing section.", section));
			m_sections[section].write!T(key, value);
		}
	}
	
	/**
	*	Checks whether the inifile has a specific key.
	*	Params:
	*		section =	The section to check within.
	*		key =		The key to check for existence.
	*	Returns: True if the key exists, falses otherwise.
	*/
	bool hasKey(string section, string key) {
		static if (sync) {
			synchronized {
				if(!hasSection(section))
					throw new IniException(format("%s is not an existing section.", section));
				return m_sections[section].hasKey(key);
			}
		}
		else {
			if(!hasSection(section))
				throw new IniException(format("%s is not an existing section.", section));
			return m_sections[section].hasKey(key);
		}
	}
	
	@property {
		/**
		*	Gets the filename of the inifile.
		*/
		string fileName() {
			static if (sync) {
				synchronized {
					return m_fileName;
				}
			}
			else {
				return m_fileName;
			}
		}
		
		/**
		*	Gets all the section names.
		*/
		string[] sectionNames() {
			static if (sync) {
				synchronized {
					return m_sections.keys;
				}
			}
			else {
				return m_sections.keys;
			}
		}
		
		/**
		*	Gets all the sections.
		*/
		IniSection!(sync)[] sections() {
			static if (sync) {
				synchronized {
					return m_sections.values;
				}
			}
			else {
				return m_sections.values;
			}
		}
	}
}
