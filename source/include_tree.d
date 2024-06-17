module include_tree;

import codeline;

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

struct DirectedGraph
{
    Node[] storage;
    Node root;

    //~ void addNode(ref Node parent, ref Node cp)
    //~ {
        //~ assert(this.canFindCycle(cp));
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
