module include_tree;

import codeline;
import std.algorithm;
import std.range;
import sorting: filenamesNotEqual;

//TODO: rename to Payload
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

    private void addExistingChild(Node* child)
    {
        assert(isNode);

        children ~= child;
    }

    private Node* createNewChild(bool createLeaf)
    {
        assert(isNode);

        auto c = new Node(isNode: !createLeaf);

        addExistingChild(c);

        return c;
    }

    private Node* addCodeLine(ref CodeLine cl)
    {
        assert(isNode);

        auto c = createNewChild(true);
        c.leaf.codeLine = &cl;

        return c;
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
    private Node*[CodeFileLineRef] indexses; //TODO: rename var

    private alias Parents = Node*[];
    private Parents[Node*] parents;

    Node root = Node(isNode: true);

    Node* getNodeByCodeLine(ref CodeLine cl)
    {
        return getOrAdd!(() => null)(indexses, cl.linemarker.fileRef);
    }

    Parents getParents(Node* node)
    {
        return parents.getOrAdd!(() => null)(node);
    }

    Node* addBaseNode()
    {
        auto node = root.createNewChild(false);

        return node;
    }

    void addExistingChild(Node* parent, Node* child)
    {
        parent.addExistingChild(child);
    }

    Node* addCodeLine(Node* parent, ref CodeLine cl)
    {
        return parent.addCodeLine(cl);
    }
}

import std.traits: isAssociativeArray;

private auto getOrAdd(alias factory, AA, I)(AA arr, I idx)
if(isAssociativeArray!AA)
{
    auto found = (idx in arr);

    if(found is null)
    {
        auto v = factory();
        arr[idx] = v;
        found = (idx in arr);
    }

    return *found;
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
