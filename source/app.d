struct CodeBlock
{
	string repeatableDescr;
	string[] code;
}

struct Storage
{
	import std.container: DList;

	static bool[string] indexArray;
	DList!CodeBlock list;

	alias list this;

	// Store if not empty and not was added previously
	void store(ref CodeBlock c)
	{
		//TODO: add better check for different blocks with same repeatableDescr
		if(c.repeatableDescr != "" && (c.repeatableDescr in indexArray) is null)
		{
			list.insertBack(c);
			indexArray[c.repeatableDescr] = true;
		}
	}
}

private bool isLineDescr(in char[] line)
{
	return line.length > 1 && line[0] == '#' && line[1] == ' ';
}

private string getRepeatablePartOfDescr(in char[] line)
{
	int quotesFound;
	string ret;

	foreach(i, c; line)
	{
		if(c == '"')
		{
			quotesFound++;

			if(quotesFound == 2)
				ret = line[2 .. i].idup; // ommits latest quote, but we don't need it for indexing
		}
	}

	assert(quotesFound == 2, "malformed line: "~line);

	return ret;
}

void main()
{
	import std.stdio;
	import std.stdio: File;
	import std.typecons: Yes;

	Storage result;

	auto file = File("tasks.c.i");

	CodeBlock current;

	foreach(line; file.byLine(Yes.keepTerminator))
	{
		// Started new block?
		if(line.isLineDescr && current.repeatableDescr != getRepeatablePartOfDescr(line))
		{
			// Store previous block
			result.store(current);

			current = CodeBlock(getRepeatablePartOfDescr(line)); //FIXME: redundant call
		}

		current.code ~= line.idup;
	}

	// Store latest
	result.store(current);

	auto store_file = File("result.i", "w");

	foreach(elem; result)
		foreach(s; elem.code)
			store_file.write(s);
}
