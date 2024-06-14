struct FileLineRef
{
    string filename;
    size_t lineNum;

    string toString() const
    {
        return filename~":"~lineNum.to!string;
    }
}

struct CodeLine
{
    FileLineRef preprocessedLineRef;
    size_t lineNum;
    CodeLinePiece[] code; // one code line can be described on few lines of a preprocessed file

    auto stripLinemarkers() const
    {
        import std.array;
        import std.algorithm;

        return code.filter!(a => a.isLinemarker).map!(a => a.piece).join;
    }
}

struct CodeLinePiece
{
    bool isLinemarker;
    string piece;
}

class SameLineDiffContentEx : Exception
{
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

import std.container: DList;
import std.exception: enforce;
import std.conv: to;

struct CodeFile
{
    string filename;
    CodeLine[] list;
    bool ignoredFile;

    private static bool byLineNum(ref CodeLine a, ref CodeLine b)
    {
        return a.lineNum < b.lineNum;
    }

    void addLine(size_t num, CodeLinePiece[] code, in FileLineRef preprocessedLineRef)
    {
        import std.range: assumeSorted;
        import std.algorithm.sorting;
        import std.algorithm.searching;
        import std.array: insertInPlace;
        import std.algorithm.comparison: equal;

        auto sortedList = assumeSorted!byLineNum(list);

        //TODO: use cl as argument?
        CodeLine cl = {lineNum: num, code: code, preprocessedLineRef: preprocessedLineRef};
        auto searchResults = sortedList.trisect(cl);

        if(searchResults[1].length != 0)
        {
            assert(searchResults[1].length == 1, "Many code lines with same line number: "~num.to!string~", line: "~code.to!string);

            const found = searchResults[1][0];

            const l1 = found.stripLinemarkers;
            const l2 = cl.stripLinemarkers;

            if(!equal(l1, l2))
            {
                string msg = ("different contents of the same "~
                    ((found.code.length > 1 || code.length > 1) ? "splitten " : "")~
                    "line in source: "~filename~":"~num.to!string~
                    "\n1: "~found.preprocessedLineRef.toString~
                    "\n2: "~preprocessedLineRef.toString~
                    "\nL1:"~found.code.to!string~
                    "\nL2:"~code.to!string
                );

                throw new SameLineDiffContentEx(msg);
            }

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

    cf.addLine(3, ["abc"], FileLineRef(filename: "1.h", lineNum: 111));
    assert(cf.list.length == 1);
    assert(cf.list[0] == CodeLine(FileLineRef(filename: "1.h", lineNum: 111), 3, ["abc"]));

    cf.addLine(2, ["def"], FileLineRef(filename: "1.h", lineNum: 222));
    assert(cf.list.length == 2);
    assert(cf.list[0] == CodeLine(FileLineRef(filename: "1.h", lineNum: 222), 2, ["def"]));

    cf.addLine(8, ["xyz"], FileLineRef(filename: "1.h", lineNum: 333));
    assert(cf.list.length == 3);
    assert(cf.list[2] == CodeLine(FileLineRef(filename: "1.h", lineNum: 333), 8, ["xyz"]));

    cf.addLine(3, ["abc"], FileLineRef(filename: "2.h", lineNum: 444));
    assert(cf.list.length == 3);
    assert(cf.list[1] == CodeLine(FileLineRef(filename: "1.h", lineNum: 111), 3, ["abc"]), cf.list.to!string);
}

/// Removes insignificant characters to the left and right of the string
string twoSidesChomp(in char[] s) pure
{
    static bool isInsign(T)(in T a)
    if(is(T==dchar) || is(T==char))
    {
        return a == '\t' || a == '\r' ||a == '\n';
    }

    size_t from;
    for(; from < s.length; from++)
    {
        const c = s[from];

        // spaces must be removed only from beginning of line
        if(!isInsign(c) && c != ' ')
            break;
    }

    size_t to;
    for(to = s.length; to > from; to--)
    {
        if(!isInsign(s[to-1]))
            break;
    }

    return s[from..to].idup;
}

unittest
{
    const s = "\t a =\t 1; \r\n ".twoSidesChomp;
    assert(s == "a =\t 1; \r\n ", "\n"~s~"|");

    assert(` a = 1;`.twoSidesChomp == `a = 1;`);
    assert(`a = 1; `.twoSidesChomp == `a = 1; `);
    assert(`a=1;`.twoSidesChomp == `a=1;`);

    const tabLineRet = "\t".twoSidesChomp;
    assert(tabLineRet == null, "\n"~tabLineRet~"|");

    assert(``.twoSidesChomp == ``);
}

struct Storage
{
    CodeFile[] codeFiles;
    static size_t[string] codeFilesIndex;

    // Store codeline if it not was added previously
    void store(in FileLineRef preprocessedLineRef, in FileLineRef codeLineRef, CodeLinePiece[] codeline)
    {
        size_t* fileIdxPtr = (codeLineRef.filename in codeFilesIndex);
        size_t fileIdx;

        if(fileIdxPtr is null)
        {
            CodeFile newFile = {filename: codeLineRef.filename};
            fileIdx = codeFiles.length;
            codeFilesIndex[newFile.filename] = fileIdx;
            codeFiles ~= newFile;
        }
        else
            fileIdx = *fileIdxPtr;

        try
            codeFiles[fileIdx].addLine(codeLineRef.lineNum, codeline, preprocessedLineRef);
        catch(SameLineDiffContentEx e)
        {
            import std.stdio;

            stderr.writeln(e.msg, "\nBoth files will be ignored");

            codeFiles[fileIdx].ignoredFile = true;
            throw e;
        }
    }
}

//TODO: rename to isLinemarker
private bool isLineDescr(in char[] line)
{
    return line.length > 1 && line[0] == '#' && line[1] == ' ';
}

struct DecodedLinemarker
{
    FileLineRef fileRef;
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

    ret.fileRef.lineNum = numAndNext[0].to!size_t;

    //TODO: support quote escaping for filenames
    const filenameAndNext = numAndNext[2][1 .. $].findSplit(`"`); // begin quote symbol skip
    ret.fileRef.filename = filenameAndNext[0].idup;

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

struct CliOptions
{
    bool refs_as_comments;
    bool prepr_refs_comments;
    bool suppress_refs;
}

int main(string[] args)
{
    import std.getopt;

    CliOptions options;

    {
        auto helpInformation = getopt(args,
            "refs_as_comments", `"Add // before # 123 "/path/to/file.h" lines"`, &options.refs_as_comments,
            "prepr_refs_comments", `Add comment lines with references to a preprocessed files`, &options.prepr_refs_comments,
            "suppress_refs", `Suppress # 123 "/path/to/file.h" lines`, &options.suppress_refs,
        );

        if (helpInformation.helpWanted)
        {
            defaultGetoptPrinter(`Usage: `~args[0]~" [PARAMETER]...\n"~
                `Takes a list of preprocessed C, C++ or Objective C files from STDIN and returns joint preprocessed file to STDOUT`,
                helpInformation.options);

            return 0;
        }
    }

    import std.stdio: stdin, stdout, File;
    import std.string: chomp;

    string filename;

    while((filename = stdin.readln) !is null)
    {
        const fname = filename.chomp;

        auto file = File(fname);

        processFile(file, fname);
    }

    //~ auto store_file = File("result.i", "w");
    auto store_file = stdout;

    bool wasIgnoredFile;

    foreach(cFile; result.codeFiles)
    {
        size_t prevCodeLineNum;

        if(cFile.ignoredFile)
            wasIgnoredFile = true;
        else
        {
            if(options.prepr_refs_comments)
                store_file.writeln(`// BEGIN code file: `~cFile.filename);

            foreach(cLine; cFile.list)
            {
                void writeLinemarker()
                {
                    if(!options.suppress_refs)
                        store_file.writeln((options.refs_as_comments ? `// ` : `# `)~cLine.lineNum.to!string~` "`~cFile.filename~`"`);
                }

                if(prevCodeLineNum == 0)
                {
                    if(options.prepr_refs_comments)
                        store_file.writeln(`// From prepr file: `~cLine.preprocessedLineRef.toString);

                    writeLinemarker(); // first line of preprocessed file
                }
                else
                {
                    const gap = cLine.lineNum - prevCodeLineNum - 1;

                    if(gap > 10)
                        writeLinemarker();
                    else
                        foreach(i; 0 .. gap)
                            store_file.writeln("");
                }

                foreach(i, physLine; cLine.code)
                {
                    if(i > 0) writeLinemarker(); // repeat linemarker for splitten line
                    store_file.writeln(physLine.piece);
                }

                prevCodeLineNum = cLine.lineNum;
            }

            if(options.prepr_refs_comments)
                store_file.writeln(`// END code file: `~cFile.filename);
        }
    }

    return wasIgnoredFile ? 3 : 0;
}

Storage result;

void processFile(F)(F file, in string preprFileName)
{
    import std.typecons: Yes;

    size_t preprFileLineNum;
    size_t notStoredPreprFileLineNum;
    DecodedLinemarker linemarker;
    DecodedLinemarker prevLinemarker;
    bool nextLineIsSameOriginalLine;
    CodeLinePiece[] currCodeLine; // one original source code line can be represented by a few preprocessed lines

    DecodedLinemarker[] stack;

    foreach(line; file.byLine(Yes.keepTerminator))
    {
        preprFileLineNum++;

        const isLineDescr = line.isLineDescr();

        if(isLineDescr)
        {
            linemarker = decodeLinemarker(line);

            if(linemarker.startOfFile)
                stack ~= linemarker;
            else if(linemarker.returningToFile)
            {
                enforce(stack.length > 0, "linemarkers stack empty, but returning linemarker found:\n"~linemarker.to!string);

                stack.length = stack.length - 1;
            }

            // Next line will be next piece of a same source line?
            nextLineIsSameOriginalLine = (prevLinemarker.fileRef == linemarker.fileRef);
        }
        else
        {
            //TODO: assert?
            enforce(linemarker.fileRef.lineNum != 0, "Line number zero is not possible: "~preprFileName~":"~preprFileLineNum.to!string);

            // Store previous line if need
            if(!nextLineIsSameOriginalLine && currCodeLine.length)
            {
                FileLineRef preprFileLine = {filename: preprFileName, lineNum: notStoredPreprFileLineNum};

                try
                    result.store(preprFileLine, prevLinemarker.fileRef, currCodeLine);
                catch(SameLineDiffContentEx e)
                    return;

                currCodeLine.length = 0;
            }

            // Store current line piece line number in prepared file for further use
            if(currCodeLine.length == 0)
                notStoredPreprFileLineNum = preprFileLineNum;

            // Process current line
            const pureLinePiece = line.twoSidesChomp();

            if(pureLinePiece.length)
                currCodeLine ~= CodeLinePiece(piece: pureLinePiece, isLinemarker: isLineDescr);

            prevLinemarker = linemarker;
            nextLineIsSameOriginalLine = false;

            linemarker.fileRef.lineNum++;
        }
    }

    enforce(stack.length == 0, "linemarkers stack isn't empty at the end of merging:\n"~stack.to!string);

    // Store latest code line
    //FIXME: code duplication
    FileLineRef preprFileLine = {filename: preprFileName, lineNum: notStoredPreprFileLineNum};

    try
        result.store(preprFileLine, prevLinemarker.fileRef, currCodeLine);
    catch(SameLineDiffContentEx e)
        return;
}
