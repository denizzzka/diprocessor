struct CodePiece
{
	string descrLine;
	string code;
}

private void storeIfNotEmpty(T)(ref T list, ref CodePiece c)
{
	if(c.descrLine != "")
		list.insertBack(c);
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
			result.storeIfNotEmpty(current);
			current = CodePiece(line.idup, null);
		}
		else
		{
			current.code ~= line;
		}
	}

	// Store latest
	result.storeIfNotEmpty(current);

	auto store_file = File("result.i", "w");

	foreach(elem; result)
	{
		store_file.write(elem.descrLine);
		store_file.write(elem.code);
	}
}
