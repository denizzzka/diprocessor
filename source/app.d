struct CodeLine
{
    size_t lineNum;
    string code;
    string addedfromPreprFile;
}

import std.container: DList;
import std.exception: enforce;
import std.conv: to;

struct CodeFile
{
    string filename;
    CodeLine[] list;

    private static bool byLineNum(ref CodeLine a, ref CodeLine b)
    {
        return a.lineNum < b.lineNum;
    }

    void addLine(string preprFile, size_t num, string code)
    {
        import std.range: assumeSorted;
        import std.algorithm.sorting;
        import std.array: insertInPlace;

        auto sortedList = assumeSorted!byLineNum(list);

        CodeLine cl = {lineNum: num, code: code, addedfromPreprFile: preprFile};
        auto found = sortedList.trisect(cl);

        if(found[1].length)
        {
            import std.algorithm.searching;

            assert(found[1].count(found[1][0]) == found[1].length, "found line pieces from a different preprocessed files: "~found[1].to!string);

            canFind
        }

        const idx = found[0].length + found[1].length;

        // Adding line
        list.insertInPlace(idx, cl);
    }
}

unittest
{
    CodeFile cf;

    cf.addLine("1.h", 3, "abc");
    assert(cf.list.length == 1);
    assert(cf.list[0] == CodeLine(3, "abc", "1.h"), cf.list.to!string);

    cf.addLine("1.h", 2, "def");
    assert(cf.list.length == 2);
    assert(cf.list[0] == CodeLine(2, "def", "1.h"));

    cf.addLine("1.h", 8, "xyz");
    assert(cf.list.length == 3);
    assert(cf.list[2] == CodeLine(8, "xyz", "1.h"));

    cf.addLine("1.h", 3, "+abc");
    assert(cf.list.length == 4);
    assert(cf.list[2] == CodeLine(3, "+abc", "1.h"), cf.list.to!string);

    cf.addLine("2.h", 3, "xyz");
    assert(cf.list.length == 5);
    assert(cf.list[2] == CodeLine(8, "xyz"), cf.list.to!string);
}

struct Storage
{
    CodeFile[] codeFiles;
    static size_t[string] codeFilesIndex;

    // Store codeline if it not was added previously
    void store(string preprFileName, string filename, size_t lineNum, string codeline)
    {
        size_t* fileIdxPtr = (filename in codeFilesIndex);
        size_t fileIdx;

        if(fileIdxPtr is null)
        {
            CodeFile newFile = {filename: filename};
            fileIdx = codeFiles.length;
            codeFilesIndex[newFile.filename] = fileIdx;
            codeFiles ~= newFile;
        }
        else
            fileIdx = *fileIdxPtr;

        codeFiles[fileIdx].addLine(preprFileName, lineNum, codeline);
    }
}

private bool isLineDescr(in char[] line)
{
    return line.length > 1 && line[0] == '#' && line[1] == ' ';
}

struct DecodedLinemarker
{
    bool isLinemarker;
    size_t lineNum;
    string filename;
    bool startOfFile;
    bool returningToFile;
    bool sysHeader;
    bool externCode;
}

private DecodedLinemarker decodeLinemarker(in char[] line)
{
    assert(line.isLineDescr);

    DecodedLinemarker ret;

    import std.string: chomp;
    import std.algorithm.searching;
    import std.algorithm.iteration: splitter;
    import std.conv: to;

    const numAndNext = findSplit(line[2 .. $].chomp, " ");

    ret.lineNum = numAndNext[0].to!size_t;

    //TODO: support quote escaping for filenames
    const filenameAndNext = numAndNext[2][1 .. $].findSplit(`"`); // begin quote symbol skip
    ret.filename = filenameAndNext[0].idup;

    // Flags processing
    auto flags = filenameAndNext[2].splitter(' ');
    ret.startOfFile = flags.canFind("1");
    ret.returningToFile = flags.canFind("2");
    ret.sysHeader = flags.canFind("3");
    ret.externCode = flags.canFind("4");

    enforce(!(ret.startOfFile && ret.returningToFile), "malformed linemarker: "~line);

    return ret;
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
        const fname = filename.chomp;

        auto file = File(fname);

        processFile(options, file, fname);
    }

    //~ auto store_file = File("result.i", "w");
    auto store_file = stdout;

    foreach(cFile; result.codeFiles)
        foreach(cLine; cFile.list)
            store_file.write(cLine.code);
}

Storage result;

void processFile(F)(in CliOptions options, F file, string preprFileName)
{
    import std.typecons: Yes;

    string currentCodeFile;
    size_t currentLineNum;

    foreach(line; file.byLine(Yes.keepTerminator))
    {
        const isLineDescr = line.isLineDescr();

        if(isLineDescr)
        {
            const linemarker = decodeLinemarker(line);

            currentCodeFile = linemarker.filename;
            currentLineNum = linemarker.lineNum;
        }
        else
        {
            result.store(preprFileName, currentCodeFile, currentLineNum, line.idup);
            currentLineNum++;

            //~ if(options.suppress_refs)
                //~ continue;

            //~ if(options.refs_as_comments)
                //~ current.code ~= "//";
        }
    }
}
