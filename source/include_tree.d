module include_tree;

import codeline;
import std.algorithm;
import std.range;
import sorting: filenamesNotEqual;

struct Node
{
    bool isNode;

    union FlexLine
    {
        CodeLine* codeLine;
        Node* child;
    }

    FlexLine[] flexLines;
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

private struct PassthroughLines
{
    static struct Stack
    {
        Node* node;
        size_t idx;
    }

    Stack[] stack;

    private auto currNode() => stack[$-1].node;
    private auto currIdx() => stack[$-1].idx;
    private void currIdxIncr() { stack[$-1].idx++; }

    this(Node* root)
    {
        pushStack(root);
        isHereNextLine();
    }

    private void pushStack(Node* node)
    {
        assert(stack.length < 100);
        stack ~= Stack(node);
    }

    private void popStack()
    {
        stack.length--;
    }

    private bool isHereNextLine()
    {
        while(true)
        {
            if(currIdx < currNode.flexLines.length)
            {
                if(currNode.isNode)
                {
                    pushStack(currNode.flexLines[currIdx].child);
                    continue;
                }
                else
                    return true; // code line found
            }
            else
            {
                if(stack.length > 1)
                {
                    popStack();
                    currIdxIncr;
                    continue;
                }
                else
                    return false; // end of lines
            }
        }
    }

    auto front()
    {
        return currNode.flexLines[currIdx].codeLine;
    }

    void popFront()
    {
        currIdxIncr;

        isHereNextLine();
    }
}

//~ private auto passThrough(ref Node*[] input)
//~ {
    //~ import std.typecons;

    //~ if(input.front.isNode)
        //~ foreach(ref n; input.front.children)
            
    //~ return input.map!(
        //~ (a)
        //~ {
            //~ if(a.isNode)
                //~ return passThrough;

            //~ auto r = tuple(a, LineDescr(a));
            //~ LineDescr.oldLm = a.linemarker;
            //~ return r;
        //~ }
    //~ );
//~ }

struct DirectedGraph
{
    private Node[] storage;
    private size_t[CodeFileLineRef] indexses;

    Node root;

    //~ private void addCodeLine(ref Node node, ref CodeLine cl)
    //~ {
        //~ assert((cl.linemarker.fileRef in indexses) is null);

        //~ indexses[cl.linemarker.fileRef] = storage.length;
        //~ storage ~= cl;

        //~ node.children
    //~ }

    Node* getNodeByCodeLine(ref CodeLine cl)
    {
        size_t* idx = (cl.linemarker.fileRef in indexses);

        if(idx is null)
            return null;

        return &storage[*idx];
    }

    void addCodeBlock(ref Node parent, CodeLine[] block)
    {
        import std.algorithm;

        foreach(ref line; block)
        {
            // find first line in stored blocks
            //~ auto found = storage.passThrough.find(line);
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
