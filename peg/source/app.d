import std.stdio;

void main()
{
    import std.string: chomp;
    import std.file;

    const string filename = stdin.readln.chomp;
    auto file = readText(filename);
    processFile(file);
}

void processFile(string file)
{
    import peg_c_lib: Parser;

    Parser parser;

    import std.array: join;
    import std.conv: to;
    import std.exception: enforce;
    import std.algorithm;

    import pegged.grammar: ParseTree;

    auto parsed = parser.parse(file);
    parsed.writeln;

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
                return [a.join, "\n"];
            default: return t.matches;
        }
    }

    foreach(s; parseToCode(parsed))
        s.write;
}
