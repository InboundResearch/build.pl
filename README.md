# Two
C++ Code Project

TODO
- Standardize makefile to support debug and release compilation options
- makefile to support src/test/resources

NOTES
- The "standardized" version of the makefile now supports making tests and a standalone executable, 
and requires the developer to use the src/main/cpp and src/test/cpp structure - the Main.cpp file
is the only standard requirement, and Test.cpp is not really special but a main implementation should
be present, with the understanding that its body will run after all the tests have loaded and run.


Thinking about build.pl, or ant - with build.xml

- recompile only objects that depend on changed files - function takes a destination and a 
  dependency chain) - if any file in the dependency chain is newer than the destination, it gets
  remade: the dependency file format has everytthing I need in the first line (or line with continuation):
  
 fileToMake.o: fileToMap.cpp fileToInclude.h anotherFileToInclude.h  
  
- need debug and release targets
- need lib and app support, with "test" as a special app, though building and running it could be
  a separate script, a shell script even... so maybe "test" isn't particularly special
- would like to be able to build and include libs that have the same filename within

{ 
    type: [application, library],
    name: main
}

could I still use "make" behind another perl script or shell script that builds the directories and 
sets environment variables that make uses?
