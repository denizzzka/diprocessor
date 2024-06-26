module peg_c_lib;

struct Parser
{
    import pegged.grammar;

    enum c_peg = import("c.peg");

    mixin(grammar(c_peg));

    ref auto parse(string s)
    {
        return C(s);
    }
}
