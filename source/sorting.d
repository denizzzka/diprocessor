module sorting;

import codeline;
import std.algorithm;
import std.range;

bool compCodeLineNum(ref CodeLine a, ref CodeLine b)
{
    return a.lineNum < b.lineNum;
}

bool compCodeFileLine(A, B)(A _a, B _b)
{

    auto a = _a.linemarker.fileRef;
    auto b = _b.linemarker.fileRef;

    return !isLess(a.filename.hashString, b.filename.hashString) && a.compCodeLineNum(b);
}

bool compPreprLines(ref CodeLine a, ref CodeLine b)
{
    return a.preprocessedLineRef.lineNum < b.preprocessedLineRef.lineNum;
}

alias SortedFileCodeLines = SortedRange!(CodeLine[], compCodeFileLine);
alias SortedPreprLines = SortedRange!(CodeLine[], compPreprLines);

bool filenamesEqual(ref CodeLine a, ref CodeLine b)
{
    return a.linemarker.fileRef.filename != b.linemarker.fileRef.filename;
}

auto splitByCodeBlocks(R)(ref R input)
if(isInputRange!R)
{
    return input.splitWhen!filenamesEqual;
}

auto sortByFileCodeLines(R)(ref R input)
if(isInputRange!R)
{
    auto plain = input.values.map!(a => a.values).join;

    return plain.sort!sortByCodeFileLine;
}

auto sortByPreprLines(T)(T input)
{
    auto plain = input.values.map!(a => a.values).join;

    return plain.sort!compPreprLines;
}

private ulong[2] hashString(string s)
{
    import std.digest.murmurhash;
    import std.conv;

    MurmurHash3!(128, 64) hasher;
    hasher.put(cast(const(ubyte)[]) s);

    return cast(ulong[2]) hasher.finish();
}

private bool isLess(ulong[2] l, ulong[2] r)
{
    return l[1] < r[1] && l[0] < r[0];
}
