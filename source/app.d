struct CodePiece
{
	string descrLine;
	string code;
}

void main()
{
	import std.stdio;
	//~ import std.array: assocArray;
	import std.container: DList;
	import std.stdio: File;
	//~ import std.algorithm: map;

	auto result = DList!CodePiece();
	CodePiece*[string] indexArray;

	auto file = File("tasks.c.i");

	CodePiece current;

	foreach(line; file.byLine())
	{
		// Started new piece of code?
		if(line.length > 1 && line[0] == '#' && line[1] == ' ')
		{
			// Save previous
			if(current.descrLine != "")
				result.insertBack(current);

			current.code = null;

			current.descrLine = line[2 .. $].idup;

			writeln("Started new: ", current);
		}
		else
		{
			import std.ascii: newline;

			current.code ~= line;
			current.code ~= newline;
		}
	}

	// Store latest
	if(current.descrLine != "")
		result.insertBack(current);

	auto store_file = File("result.i", "w");

	foreach(elem; result)
	{
		store_file.writeln(elem.descrLine);
		store_file.write(elem.code);
	}
}
