module codeline;

import std.conv: to;

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
    DecodedLinemarker linemarker;
    size_t lineNum() const { return linemarker.fileRef.lineNum; };
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
