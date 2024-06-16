module include_tree;

//~ import std.exception;

import codeline: CodeLine;

struct Node
{
    Node* parent;
    string filename; // header name

    union
    {
        CodeLine*[] codeLines;
        Node*[] optionalBranches;
    }

    bool empty() const
    {
        return optionalBranches.length == 0 && codeLines.length == 0;
    }
}

struct DirectedGraph
{
    import std.container;

    SList!Node storage;
    Node*[][string] byFilename;

    Node* createNode(Node* parent, string filename)
    {
        auto node = Node(filename: filename, parent: parent);

        storage.insert(node);

        Node* added = &storage.front();
        byFilename[added.filename] ~= added;

        parent.optionalBranches ~= added;

        return added;
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

    foreach(ref br; c.optionalBranches)
    {
        if(graph.canFindCycle(*br, checked))
            return true;
    }

    return false;
}
