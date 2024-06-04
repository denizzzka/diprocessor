struct CodePiece
{
	string descrLine;
	string code;
}

struct Storage
{
	import std.container: DList;

	static bool[string] indexArray;
	DList!CodePiece list;

	alias list this;

	// Store if not empty and not was added previously
	void store(ref CodePiece c)
	{
		if(c.descrLine != "" /*&& (c.descrLine in indexArray) is null*/)
		{
			list.insertBack(c);
			indexArray[c.descrLine] = true;
		}
	}
}

void main()
{
	import std.stdio;
	import std.stdio: File;
	import std.typecons: Yes;

	Storage result;

	auto file = File("tasks.c.i");

	CodePiece current;

	foreach(line; file.byLine(Yes.keepTerminator))
	{
		// Started new piece of code?
		if(line.length > 1 && line[0] == '#' && line[1] == ' ')
		{
			result.store(current);
			current = CodePiece(line.idup, null);
		}
		else
		{
			current.code ~= line;
		}
	}

	// Store latest
	result.store(current);

	auto store_file = File("result.i", "w");

	foreach(elem; result)
	{
		store_file.write(elem.descrLine);
		store_file.write(elem.code);
	}
}
