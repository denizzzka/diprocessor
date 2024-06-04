struct CodeBlock
{
    string repeatableDescr;
    string[] code;
}

struct Storage
{
    import std.container: DList;

    static bool[string] storageIndexArray;
    DList!CodeBlock list;
    alias list this;

    // Store if not empty and not was added previously
    void store(ref CodeBlock c)
    {
        //TODO: add better check for different blocks with same repeatableDescr
        if(c.repeatableDescr != "" && (c.repeatableDescr in storageIndexArray) is null)
        {
            list.insertBack(c);
            storageIndexArray[c.repeatableDescr] = true;
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

import args: Arg;

struct CliOptions
{
    @Arg("Add // before # 123 \"/path/to/file.h\" lines") bool refs_as_comments;
    @Arg("Suppress # 123 \"/path/to/file.h\" lines") bool suppress_refs;
}

void main(string[] args)
{
    import args: parseArgsWithConfigFile;

    CliOptions options;
    parseArgsWithConfigFile(options, args);
    //TODO: detect unrecognized options

    import std.stdio: stdin, stdout, File;
    import std.string: chomp;

    string filename;

    while((filename = stdin.readln) !is null)
    {
        auto file = File(filename.chomp);

        processFile(options, file);
    }

    //~ auto store_file = File("result.i", "w");
    auto store_file = stdout;

    foreach(elem; result)
        foreach(s; elem.code)
            store_file.write(s);
}

Storage result;

void processFile(F)(in CliOptions options, F file)
{
    import std.typecons: Yes;

    CodeBlock current;

    foreach(line; file.byLine(Yes.keepTerminator))
    {
        const isLineDescr = line.isLineDescr();
        string repeatableDescr;

        // Started new block?
        if(isLineDescr && ((repeatableDescr = getRepeatablePartOfDescr(line)) != current.repeatableDescr))
        {
            // Store previous block
            result.store(current);

            // Create new block
            current = CodeBlock(repeatableDescr);
        }

        if(isLineDescr)
        {
            if(options.suppress_refs)
                continue;

            if(options.refs_as_comments)
                current.code ~= "//";
        }

        current.code ~= line.idup;
    }

    // Store latest
    result.store(current);
}
