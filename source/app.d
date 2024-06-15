struct FileLineRef
{
    string filename;
    size_t lineNum;

    string _toString() const
    {
        return filename~":"~lineNum.to!string;
    }
}

import std.typecons: Typedef;

alias PreprFileLineRef = Typedef!(FileLineRef, FileLineRef.init, "preproc");
alias CodeFileLineRef = Typedef!(FileLineRef, FileLineRef.init, "code or h");

struct CodeLine
{
    PreprFileLineRef preprocessedLineRef;
    size_t lineNum;
    CodeLinePiece[] code; // one code line can be described on few lines of a preprocessed file

    private auto stripLinemarkers() const
    {
        import std.array;
        import std.algorithm;

        return code.map!(a => a.piece).join;
    }

    bool equal(in CodeLine f) const
    {
        import std.algorithm.comparison: equal;

        const l1 = f.stripLinemarkers;
        const l2 = this.stripLinemarkers;

        return equal(l1, l2);
    }

    bool empty() const
    {
        return code.length == 0;
    }

    void addPiece(string piece)
    {
        code ~= CodeLinePiece(piece: piece);
    }
}

struct CodeLinePiece
{
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

    void addLine(ref CodeLine cl)
    {
        import std.range: assumeSorted;
        import std.algorithm.sorting;
        import std.algorithm.searching;
        import std.array: insertInPlace;

        auto sortedList = assumeSorted!byLineNum(list);

        auto searchResults = sortedList.trisect(cl);

        if(searchResults[1].length != 0)
        {
            assert(searchResults[1].length == 1, "Many code lines with same line number: "~cl.lineNum.to!string~", line: "~cl.code.to!string);

            const found = searchResults[1][0];

            if(!cl.equal(found))
            {
                string msg = ("different contents of the same "~
                    ((found.code.length > 1 || cl.code.length > 1) ? "splitten " : "")~
                    "line in source: "~filename~":"~cl.lineNum.to!string~
                    "\n1: "~found.preprocessedLineRef._toString~
                    "\n2: "~cl.preprocessedLineRef._toString~
                    "\nL1:"~found.code.to!string~
                    "\nL2:"~cl.code.to!string
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
    void store(in string codeFilename, ref CodeLine codeline)
    {
        size_t* fileIdxPtr = (codeFilename in codeFilesIndex);
        size_t fileIdx;

        if(fileIdxPtr is null)
        {
            CodeFile newFile = {filename: codeFilename};
            fileIdx = codeFiles.length;
            codeFilesIndex[newFile.filename] = fileIdx;
            codeFiles ~= newFile;
        }
        else
            fileIdx = *fileIdxPtr;

        try
            codeFiles[fileIdx].addLine(codeline);
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
    CodeFileLineRef fileRef;
    bool startOfFile;
    bool returningToFile;
    bool sysHeader;
    bool externCode;

    string getCanonicalRepr() const pure
    {
        return `# `~fileRef.lineNum.to!string~` `~fileRef.filename;
    }
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

    foreach(ref const cFile; result.codeFiles)
    {
        size_t prevCodeLineNum;

        if(cFile.ignoredFile)
            wasIgnoredFile = true;
        else
        {
            if(options.prepr_refs_comments)
                store_file.writeln(`// BEGIN code file: `~cFile.filename);

            foreach(ref const cLine; cFile.list)
            {
                void writeLinemarker()
                {
                    if(!options.suppress_refs)
                        store_file.writeln((options.refs_as_comments ? `// ` : `# `)~cLine.lineNum.to!string~` "`~cFile.filename~`"`);
                }

                if(prevCodeLineNum == 0)
                {
                    if(options.prepr_refs_comments)
                        store_file.writeln(`// From prepr file: `~cLine.preprocessedLineRef._toString);

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

                foreach(i, ref const physLine; cLine.code)
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

import std.range;
import std.stdio;

bool processFile(F)(F file, in string preprFileName)
{
    auto input = file.byLine(Yes.keepTerminator);

    string[] filesOrder;
    auto allLines = input.splitIntoCodeLines(filesOrder);

    foreach(ref filename; filesOrder)
    {
        import std.algorithm.sorting;

        auto sorted = allLines[filename].values.sort!("a.lineNum < b.lineNum");

        foreach(ref line; sorted)
        {
            try
                result.store(filename, line);
            catch(SameLineDiffContentEx e)
                return false;
        }
    }

    return true;
}

auto splitIntoCodeLines(R)(ref R input, out string[] filesOrder)
if(isInputRange!R)
{
    PreprFileLineRef preprFileLine;
    DecodedLinemarker linemarker;
    CodeLine[size_t][string] ret;

    while(true)
    {
        if(input.empty)
            return ret;

        preprFileLine.lineNum++;

        const isLineDescr = input.front.isLineDescr();

        if(isLineDescr)
            linemarker = decodeLinemarker(input.front);
        else
        {
            const piece = input.front.twoSidesChomp();

            if(piece.length)
            {
                const fref = linemarker.fileRef;

                auto file = (fref.filename in ret);

                if(file is null)
                    filesOrder ~= fref.filename;

                CodeLine* lineObj = (file is null) ? null : (fref.lineNum in *file);

                if(lineObj is null)
                {
                    ret[fref.filename][fref.lineNum] = CodeLine(
                        preprocessedLineRef: preprFileLine,
                        lineNum: linemarker.fileRef.lineNum
                    );

                    lineObj = &ret[fref.filename][fref.lineNum];
                }

                lineObj.addPiece(piece);
            }

            linemarker.fileRef.lineNum++;
        }

        input.popFront();
    }
}
