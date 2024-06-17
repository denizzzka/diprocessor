module include_tree;

import codeline;
import std.algorithm;
import std.range;
import sorting: filenamesNotEqual;

struct Leaf
{
    CodeLine* codeLine;
}

struct Node
{
    bool isNode; // or leaf

    union
    {
        Leaf leaf;
        Node*[] children;
    }

    void addChild(Node* child)
    {
        assert(isNode);

        children ~= child;
    }

    Node* addNewChild(bool createNode)
    {
        assert(isNode);

        auto c = new Node(isNode: createNode);

        addChild(c);

        return c;
    }

    void addCodeLine(ref CodeLine cl)
    {
        assert(isNode);

        auto c = addNewChild(false);
        c.leaf.codeLine = &cl;
    }
}

struct PassthroughLines
{
    //~ static assert(isInputRange!PassthroughLines);

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

    private Node* currChild()
    {
        return currNode.children[currIdx];
    }

    private bool currIdxPointsToLeaf()
    {
        return !currChild.isNode;
    }

    private bool isHereNextLine()
    {
        while(true)
        {
            if(currIdx < currNode.children.length)
            {
                if(!currIdxPointsToLeaf)
                {
                    pushStack(currChild);
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

        return currNode.children[currIdx].leaf.codeLine;
    }

    bool empty()
    {
        return !currIdxPointsToLeaf && currIdx >= currNode.children.length;
    }

    void popFront()
    {
        currIdxIncr;

        isHereNextLine();
    }
}

struct DirectedGraph
{
    private size_t[CodeFileLineRef] indexses;

    Node root = Node(isNode: true);

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
