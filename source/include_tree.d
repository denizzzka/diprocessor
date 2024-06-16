module include_tree;

//~ import std.exception;

import codeline: CodeLine;

struct Node
{
    string filename; // header name

    //FIXME:
    //~ union
    //~ {
    CodeLine*[] codelines;
    size_t[] optionalBranchesIdx;
    //~ }

    bool empty() const
    {
        return optionalBranchesIdx.length == 0 && codelines.length == 0;
    }
}

struct DirectedGraph
{
    Node[] storage;
    Node root;

    ref Node addNode(ref Node parent, ref Node cp)
    {
        assert(this.canFindCycle(cp));

        parent.optionalBranchesIdx ~= storage.length;
        storage ~= cp;

        return storage[$-1];
    }
}

private bool canFindCycle(in DirectedGraph graph, ref const Node c)
{
    bool[Node*] checked;

    return graph.canFindCycle(c, checked);
}

private bool canFindCycle(in DirectedGraph graph, ref const Node c, ref bool[Node*] checked)
{
    if(&c in checked)
        return true;
    else
        checked[&c] = true;

    foreach(idx; c.optionalBranchesIdx)
    {
        if(graph.canFindCycle(graph.storage[idx], checked))
            return true;
    }

    return false;
}
