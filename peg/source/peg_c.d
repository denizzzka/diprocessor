module peg_c;

struct Parser
{
    import pegged.grammar;

    enum c_peg = import("c.peg");

    mixin(grammar(c_peg));
}
