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
	import std.typecons: Yes;
	//~ import std.algorithm: map;

	auto result = DList!CodePiece();
	CodePiece*[string] indexArray;

	auto file = File("tasks.c.i");

	CodePiece current;

	foreach(line; file.byLine(Yes.keepTerminator))
	{
		// Started new piece of code?
		if(line.length > 1 && line[0] == '#' && line[1] == ' ')
		{
			// Save previous
			if(current.descrLine != "")
				result.insertBack(current);

			// Init new
			current = CodePiece(line.idup, null);
		}
		else
		{
			current.code ~= line;
		}
	}

	// Store latest
	if(current.descrLine != "")
		result.insertBack(current);

	auto store_file = File("result.i", "w");

	foreach(elem; result)
	{
		store_file.write(elem.descrLine);
		store_file.write(elem.code);
	}
}
