UPD: This approach turned out to be ineffective: in some cases it is
impossible to determine from .i files whether code needs to be inserted
inside of another expression or whether it itself is an expression

=======
Takes a list of preprocessed C, C++ or Objective C files from STDIN and returns joint preprocessed file to STDOUT

Build (for non-D users):
========================

1. Install D compiler and DUB package manager (same package usually - DUB is a part of D compiler distribution)
2. Clone this repo and change dir to it
3. $ dub build
4. $ ./diprocessor --help
