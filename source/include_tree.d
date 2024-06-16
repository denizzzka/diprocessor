module include_tree;

//~ import std.exception;

struct CodePiece
{
    string filename; // header name
    size_t beginLineNum; // physical lines in header
    size_t endLineNum;
}

struct Node
{
    CodePiece piece;
    size_t[] optionalBranchesIdx;
}

struct OrientedGraph
{
    Node[] storage;
    Node root;

    void addNode(ref Node parent, ref Node cp)
    {
        assert(this.canFindCycle(cp));

        parent.optionalBranchesIdx ~= storage.length;
        storage ~= cp;
    }
}

private bool canFindCycle(in OrientedGraph graph, ref const Node c)
{
    bool[Node*] checked;

    return graph.canFindCycle(c, checked);
}

private bool canFindCycle(in OrientedGraph graph, ref const Node c, ref bool[Node*] checked)
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
