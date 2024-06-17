module include_tree;

import codeline;
import std.algorithm;
import std.range;
import sorting: filenamesNotEqual;

struct CodeBlock
{
    CodeLine*[] codeBlock;
}

struct Node
{
    GElem*[] children;
}

struct GElem
{
    bool isNode;

    union
    {
        CodeBlock codeBlock;
        Node node;
    }
}

private struct LineDescr
{
    static DecodedLinemarker oldLm;
    bool isStartOfFile;
    bool isReturningToFile;

    this(ref CodeLine cl)
    {
        const isSameFile = filenamesNotEqual(oldLm, cl.linemarker);

        if(!isSameFile)
        {
            isStartOfFile = cl.linemarker.startOfFile;

            assert(!isStartOfFile == cl.linemarker.returningToFile);

            isReturningToFile = cl.linemarker.returningToFile;
        }
    }
}

private auto passThrough(R)(ref R input)
if(isInputRange!R)
{
    import std.typecons;

    return input.map!(
        (a)
        {
            auto r = tuple(a, LineDescr(a));
            LineDescr.oldLm = a.linemarker;
            return r;
        }
    );
}

struct DirectedGraph
{
    private CodeLine[] storage;
    private size_t[CodeFileLineRef] indexses;

    Node root;

    private void addCodeLine(ref Node node, ref CodeLine cl)
    {
        assert((cl.linemarker.fileRef in indexses) is null);

        indexses[cl.linemarker.fileRef] = storage.length;
        storage ~= cl;

        //~ node.children
    }

    void addCodeBlock(ref Node parent, CodeLine[] block)
    {
        auto asd = block.passThrough;

        foreach(ref line; block)
        {

        }
    }

    //~ ref CodeLine fetchOrAddCodeLine(ref CodeLine cl)
    //~ {
        //~ size_t* idx = (cl.linemarker.fileRef in indexses);


    //~ }
}

//~ private bool canFindCycle(in DirectedGraph graph, ref const Node c)
//~ {
    //~ bool[Node*] checked;

    //~ return graph.canFindCycle(c, checked);
//~ }

//~ private bool canFindCycle(in DirectedGraph graph, ref const Node c, ref bool[Node*] checked)
//~ {
    //~ if(&c in checked)
        //~ return true;
    //~ else
        //~ checked[&c] = true;

    //~ foreach(idx; c.optionalBranchesIdx)
    //~ {
        //~ if(graph.canFindCycle(graph.storage[idx], checked))
            //~ return true;
    //~ }

    //~ return false;
//~ }
