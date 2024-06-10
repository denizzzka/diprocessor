import std.stdio;

void main()
{
    const string filename = "esp_https_ota.c";
    auto file = File(filename);
    processFile(file);
}

void processFile(File file)
{
    import peg_c: Parser;

    Parser parser;

    foreach(line; file.byLine)
    {
    }
}
