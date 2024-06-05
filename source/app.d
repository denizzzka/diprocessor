struct CodeLine
{
    size_t lineNum;
    string[] code; // one code line can be described on few lines of a preprocessed file
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

    void addLine(size_t num, string[] code)
    {
        import std.range: assumeSorted;
        import std.algorithm.sorting;
        import std.array: insertInPlace;

        auto sortedList = assumeSorted!byLineNum(list);

        CodeLine cl = {lineNum: num, code: code};
        auto searchResults = sortedList.trisect(cl);

        if(searchResults[1].length != 0)
        {
            assert(searchResults[1].length == 1, "Many code lines with same line number: "~num.to!string~", line: "~code.to!string);

            // Nothing to do: line already stored
            return;
        }

        // Adding line
        list.insertInPlace(searchResults[0].length, cl);
    }
}

unittest
{
    CodeFile cf;

    cf.addLine(3, ["abc"]);
    assert(cf.list.length == 1);
    assert(cf.list[0] == CodeLine(3, ["abc"]));

    cf.addLine(2, ["def"]);
    assert(cf.list.length == 2);
    assert(cf.list[0] == CodeLine(2, ["def"]));

    cf.addLine(8, ["xyz"]);
    assert(cf.list.length == 3);
    assert(cf.list[2] == CodeLine(8, ["xyz"]));

    cf.addLine(3, ["abc"]);
    assert(cf.list.length == 3);
    assert(cf.list[1] == CodeLine(3, ["abc"]), cf.list.to!string);
}

struct Storage
{
    CodeFile[] codeFiles;
    static size_t[string] codeFilesIndex;

    // Store codeline if it not was added previously
    void store(string codeFileName, size_t lineNum, string[] codeline)
    {
        size_t* fileIdxPtr = (codeFileName in codeFilesIndex);
        size_t fileIdx;

        if(fileIdxPtr is null)
        {
            CodeFile newFile = {filename: codeFileName};
            fileIdx = codeFiles.length;
            codeFilesIndex[newFile.filename] = fileIdx;
            codeFiles ~= newFile;
        }
        else
            fileIdx = *fileIdxPtr;

        codeFiles[fileIdx].addLine(lineNum, codeline);
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
        auto file = File(filename.chomp);

        processFile(options, file);
    }

    //~ auto store_file = File("result.i", "w");
    auto store_file = stdout;

    foreach(cFile; result.codeFiles)
        foreach(cLine; cFile.list)
            foreach(physLine; cLine.code)
                store_file.write(physLine);
}

Storage result;

void processFile(F)(in CliOptions options, F file)
{
    import std.typecons: Yes;

    string currentCodeFile; // original source (.h file usually)
    size_t currentLineNum; // original source line number (number inside of .h file)
    string[] currCodeLine; // one original source code line can be described by a few preprocessed lines

    foreach(line; file.byLine(Yes.keepTerminator))
    {
        const isLineDescr = line.isLineDescr();
        bool nextLineIsSameOriginalLine;

        if(isLineDescr)
        {
            const linemarker = decodeLinemarker(line);

            // Next line will be next piece of a same source line?
            nextLineIsSameOriginalLine = (currentCodeFile == linemarker.filename && currentLineNum == linemarker.lineNum + 1);

            if(nextLineIsSameOriginalLine)
                currentLineNum--;
            else
            {
                // Store previous
                result.store(currentCodeFile, currentLineNum, currCodeLine);

                // Prepare to new
                currCodeLine.length = 0;
                currentCodeFile = linemarker.filename;
                currentLineNum = linemarker.lineNum;
            }
        }
        else
        {
            enforce(currentLineNum != 0, "Line number zero is not possible");
            currCodeLine ~= line.idup;
            currentLineNum++;
        }
    }
}
