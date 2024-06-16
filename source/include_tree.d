module include_tree;

//~ import std.exception;

import codeline: CodeLine;

struct Node
{
    Node* parent; //FIXME: graph, not tree
    debug string filename; // header name

    static union Content
    {
        CodeLine[]* codeLine;
        Node[]* branch;
    }

    bool empty() const
    {
        return content.length == 0;
    }
}

struct DirectedGraph
{
    import std.container;

    SList!Node storage;
    Node*[string] byFilename;

    Node* continueProcessingFile(in string filename, Node* parent = null)
    {
        Node** node = (filename in byFilename);

        if(node is null)
            *node = createNode(filename, parent);

        return *node;
    }

    private Node* createNode(in string filename, Node* parent)
    {
        auto node = Node(parent: parent);
        debug node.filename = filename;

        storage.insert(node);

        Node* added = &storage.front();
        byFilename[filename] = added;

        return added;
    }

    void addContent(Node* node, ref CodeLine cl)
    {
        node.content ~= Node.Content(&cl);
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
