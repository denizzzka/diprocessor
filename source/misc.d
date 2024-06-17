module misc;

//~ import std.range;

//~ auto splitByCodeBlocksAdv(R)(ref R input)
//~ if(isInputRange!R)
//~ {
    //~ input.slide(2).map!(
        //~ (a)
        //~ {
            //~ assert(a.length);

            //~ if(a.length < 2)
                //~ return tuple(a[0], LineDescr(isStartOfFile: true); // for one-liner blocks line is always starts new block
            //~ else
                //~ return tuple(a[0], LineDescr(isStartOfFile: true);

         //~ = tuple(b, LineDescr(a , b)));

    //~ // if one piece then return as one new block
//~ }

//~ struct LineDescr
//~ {
    //~ bool isStartOfFile;
    //~ bool isReturningToFile;
//~ }

//~ private fillLDescr(ref LineDescr ret, ref CodeLine oldCl, ref CodeLine cl)
//~ {
    //~ const isSameFile = filenamesNotEqual(oldCl.linemarker, cl.linemarker);

    //~ if(!isSameFile)
    //~ {
        //~ ret.isStartOfFile = cl.linemarker.startOfFile;

        //~ assert(!isStartOfFile == cl.linemarker.returningToFile);

        //~ ret.isReturningToFile = true;
    //~ }
//~ }
