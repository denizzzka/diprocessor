import std.stdio;
import std.ascii: newline;

void main()
{
    import std.string: chomp;

    const string filename = stdin.readln.chomp;
    processFile(filename);
}

void processFile(in string filename)
{
    import peg_c_lib: Parser;

    Parser parser;

    import std.array: join;
    import std.conv: to;
    import std.exception: enforce;
    import std.algorithm;

    import std.file: readText;
    import pegged.grammar: ParseTree;

    // pegged counts lines unconventionally, from 0. That's why a newline is added here
    auto file = newline~readText(filename);
    auto parsed = parser.parse(file);

    if(!parsed.successful)
    {
        // get only first failed ExternalDeclaration
        foreach(ref c; parsed.children[0].children)
            if(!c.successful && c.name == "C.ExternalDeclaration")
            {
                import std.algorithm.searching;

                const linenum = file[0 .. c.end].count("\n");
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
