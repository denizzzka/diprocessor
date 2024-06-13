import std.stdio;
import std.ascii: newline;

void main()
{
    import std.string: chomp;
    import std.typecons: Yes;
    import std.algorithm;

    const string filename = stdin.readln.chomp;
    auto file = File(filename);

    size_t linenum;
    string fileChunk;
    foreach(l; file.byLine(Yes.keepTerminator))
    {
        linenum++;

        fileChunk ~= l.idup;

        if(l.startsWith(`// END code file: `))
        {
            processFile(fileChunk, filename, linenum);
            fileChunk = "";
        }
    }

    processFile(fileChunk, filename, linenum);
}

void processFile(string fileChunk, in string filename, in size_t preprFileLinenum)
{
    import peg_c_lib: Parser;

    Parser parser;

    import std.array: join;
    import std.conv: to;
    import std.exception: enforce;
    import std.algorithm;

    import pegged.grammar: ParseTree;

    auto parsed = parser.parse(fileChunk);

    if(!parsed.successful)
    {
        // get only first failed ExternalDeclaration
        foreach(ref c; parsed.children[0].children)
            if(!c.successful && c.name == "C.ExternalDeclaration")
            {
                import std.algorithm.searching;

                const linenum = preprFileLinenum + fileChunk[0 .. c.end].count("\n");
                throw new Exception(`Parse error in `~filename~`:`~linenum.to!string~newline~c.toString);
            }
    }

    static string[] parseToCode(ref ParseTree t)
    {
        static string[] loopOverAll(ref ParseTree[] ptlist, bool stripCompoundStatement = false)
        {
            string[] ret;

            foreach(ref c; ptlist)
                if(stripCompoundStatement && c.name == "C.CompoundStatement")
                    ret ~= [";"];
                else
                    ret ~= parseToCode(c);

            return ret;
        }

        switch(t.name)
        {
            case "C":
            case "C.TranslationUnit":
            case "C.ExternalDeclaration": return loopOverAll(t.children);
            case "C.FunctionDefinition":
                // special loop strips body of function
                auto a = loopOverAll(t.children, true);
                return [a.join, newline];
            default: return t.matches;
        }
    }

    foreach(s; parseToCode(parsed))
        s.write;
}
