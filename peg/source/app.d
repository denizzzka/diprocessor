import std.stdio;

void main()
{
    const string filename = "esp_https_ota.c";
    auto file = File(filename);
    processFile(file);
}

void processFile(File file)
{
    import peg_c_lib: Parser;

    Parser parser;

    import std.array: join;
    import std.conv: to;
    import std.exception: enforce;

    auto parsed = parser.parse(file.byLine.join.to!string);

    foreach(ref child; parsed.children)
    {
        enforce(child.successful, "Parse error");
        child.name.writeln;
    }
}
