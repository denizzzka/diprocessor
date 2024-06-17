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

    void addChild(Node* child)
    {
        assert(isNode);

        flexLines ~= FlexLine(child: child);
    }

    void addCodeLine(ref CodeLine cl)
    {
        assert(!isNode);

        flexLines ~= Node.FlexLine(codeLine: &cl);
    }
}

struct PassthroughLines
{
    static assert(isInputRange!PassthroughLines);

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
                {
                    currIdxIncr; // set empty condition even if zero elements inside of root range
                    return false; // end of lines
                }
            }
        }
    }

    auto front()
    {
        assert(!empty);

        return currNode.flexLines[currIdx].codeLine;
    }

    bool empty()
    {
        return currIdx >= currNode.flexLines.length;
    }

    void popFront()
    {
        currIdxIncr;

        isHereNextLine();
    }
}

struct DirectedGraph
{
    private Node[] storage;
    private size_t[CodeFileLineRef] indexses;

    Node root = Node(isNode: true);

    private Node* createNode(ref Node parent)
    {
        assert(parent.isNode);

        storage ~= Node.init;
        parent.flexLines ~= Node.FlexLine(child: &storage[$-1]);

        return &storage[$-1];
    }

    Node* getNodeByCodeLine(ref CodeLine cl)
    {
        size_t* idx = (cl.linemarker.fileRef in indexses);

        if(idx is null)
            return null;

        return &storage[*idx];
    }

    Node* addBaseNode()
    {
        auto node = createNode(root);
        node.isNode = true;

        return node;
    }
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
