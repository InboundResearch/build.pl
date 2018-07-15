# build.pl
## quick-start
build.pl is an easy to use perl script that does what "make" does, but without any configuration needed. If you just want to throw down a quick command line program, create a directory that contains a "source/<project>" directory with your *.cpp file(s) in it, and then run build.pl. The default build context supplies debug and release configurations, and will automatically build your project.

This structure is natural if you create project in GitHub, and is probably relatively familiar to users of Apache Maven (mvn).

## about
The goal is to effectively develop and test a project in C++ without being tied to a specific development platform.

The key word in that goal is "effectively".

The year is 2018. I haven't worked in a strictly C++ ecosystem for nearly a decade. In that time, I have been working in Java, C#, and Javascript, among a host of other less popular languages. All of them have mature development capabilities that revolve around a de facto standard sequence of events roughly matching:
* check-out project files
* modify sources
* resolve dependencies
* build
* run unit tests
* debug
* check-in changed project files
* run integration tests
* deploy

Each of these development components can be broken down in great detail, but IDEs and build tools like Apache Maven or Apache Ant (with Ivy) dominate the landscape of these operations, along with fundamental tools like Git and Jenkins.

So imagine my surprise, returning to developing in C++ in a long-term project running on RedHat 7, to find that the old standby "make" is still the standard, and to realize that this comes up very short. 

## requirements
What I need is to be able to start a project and go:
* Zero configuration required to start, add configuration only as needed to support increaded project complexity. 
* Build my projects, keeping the object files and targets in a separate directory from the sources (so I can organize my sources intelligently).
* Minimal structural requirements (sources must be organized in a flat directory tree), use other scripting structures to support more complex project hierarchies.
* Efficiency, using threaded operation where possible.
* Relatively platform agnostic (I'm focused on g++ right now - developing for RedHat7, Ubuntu, Debian on Raspberry Pi, MacOS, and Cygwin on Windows). 
* Support building and run one or more tests, along with the actual target application(s). 
* Use modern standards for configurations (JSON).

## rant
It's perhaps a conversation for another day, but there is no IDE that fully delivers for C++ development in Unix environments. Eclipse with CDT is highly unstable, unfinished, and just not up to snuff when compared to state-of-the-art Java IDEs. Visual Studio Code doesn't do Intellisense with C++ in a useful way, and even my trusty IntelliJ delivers CLion, which only works for a specific type of pipeline. MacOS requires that debuggers are signed by the App Store, so CLion is the only GDB-based solution that works on that platform. XCode, while a staple of MacOS development, has a fundamentally broken windowing model, and the clang toolkit they ship is well behind the C++ standard, or the freely available clang package.

To be clear, I'll acknowledge that "make" works and works well - when you have configured the makefile for your needs. But the reality is that there is no easy start to using "make". There are a few good "general purpose" C++ makefiles if you hunt around on StackOverflow, but you are really on your own if you don't already have a makefile. You have to learn "make" just like any other form of programming language, and once you get past the basic capabilities of checking dependencies, "make" gets hard to use. You quickly find yourself wishing you could just write a shell script, instead.

The "state of the art" is CMake, a tool with an obtuse syntax of its own that builds hyper-complex makefiles for you, and loosely integrates a relatively small ecosystem of testing tools. It's a good start, but is more meant to solve the portability problem than the build problem.


## prerequisites
build.pl uses ... Perl ... so you will need that installed. It's tested on v. 5.16 and up, but does require threads. On MacOS, I use perlbrew, which installs an unthreaded version of perl by default. You will need to install it with a command line like:
  
    > perlbrew install --as perl-5.16.0t -Dusethreads perl-5.16.0

Once Perl is installed, you will also need to use CPAN to install the JSON module:

    > cpan JSON
    
I use a cloned copy of the build.pl repository, and add build.pl/bin to my path. You can "install" it however you like.
 
## build configuration files:
build configuration files in json format, "build.json", are read at multiple levels. the
first default is in the build script binary directory and contains global defaults. the
second default is at the root of the project directory, and the final build
configuration can be found inside each individual target. each variable requested is
processed to the lowest level configuration in which it is found, so that most defaults
can be specified at the root config level, and overridden at the lower levels if
necessary, possibly using the parent value in its redefinition. configuration variables
can also be redefined at the command line.

example build.json:

           {
               "type": "library",
               "dependencies":[],
               "configurations": {
                   "debug": {
                       "compilerOptions": "-g -D_DEBUG_",
                       "linkerOptions": ""
                   },
                   "release": {
                       "compilerOptions": "-O3 -D_NDEBUG_",
                       "linkerOptions": ""
                   }
               }
           }

## target names:
source directories are named for the final product name (e.g. directory "math" builds a
library called "math". this cannot be overridden.

## variables:
configuration variables are a "$" followed by any valid camel-case identifiers:

`$[a-z][A-Za-z0-9]+`

configuration variables are mostly defined statically, but can be specified to be
interpreted by a shell or by variable replacement. replacements are processed
recursively starting with step (1) until no more substitutions are performed:

1)  `$[name]` is a simple replacement from the current build configuration dictionary.
   if `[name]` is not a known build configuration variable, it is left unchanged. if
   the replacement value is "*" or is not a simple scalar, it is left unchanged.

2)  a `$([exec])` construct replaces the string with the value returned by a shell
  executing the given command.

3)  a `?([ifdef]:[ifndef])` structure in a variable value declares a conditional
   definition, where the ifdef side is executed if the variable is already defined, and
   the ifndef side is executed if it is not. omitting the ":" is valid if there is no
   ifndef. omitting the ifdef is equivalent to un-defining the value, so erasing a
   setting is "?()". a simple "$" before the ":" is sufficient to indicate the existing
   value, but complex redefinitions should use the variable name normally.

4)  a `!` at the beginning of a variable value declares it to be "final", and no further
   overrides will be processed.

## build configuration hierarchy:
when a new build configuration (N) context is opened, it is concatenated with the
existing top level build configuration (E), to produce a resulting build configuration
context (R), as follows:

1)  for all variables (V) in (N), R(V) = N(V)xE, where the () notation indicates the
variable subsitution process described separately, and x indicates the source of the values
used in the substitution.

2) for all variables (U) in (E), if R(U) does not already exist, R(U) = E(U).

(R) is cached by the build configuration system according to its context name, which is
one of: GLOBAL_LEVEL, PROJECT_LEVEL, COMMAND_LINE, or [target].

a later "reduce" step is supported, which will force all variables in a context to be
resolved using its own definitions.

any particular concatenation of build configurations can be requested via a named
build configuration and a new dictionary.

## dependencies:
targets (library or application) might depend on another target being built first, so
dependencies can be named in the array variable "dependencies". the include paths sent
to the compiler will include the dependency directories as -I includes, and the library
paths sent to the linker will include the dependency directories as -L libs.

another option would be to reference all external includes with a relative path,
i.e. `#include "common/Types.h"`

## command line options:
command line options can be used to override build configuration settings. in practice,
the only settings allowed are "buildConfigurationFileName" (which is processed before
the project-level configuration), and "target" and "configuration" (which are processed
after the project-level configuration). this effect is achieved by processing the
command line build configurations both before and after the project-level configuration,
which could lead to unexpected results if the end-user is attempting to set these three
values in both places.

NOTE - all other build configuration variable values are too complicated to support from
the command line. they may be specified, but the result is undefined and unsupported,
and might be subject to later revision.

TODO: NOTE - the builder caches major configurations at the root of the "$target" directory,
and since command line options can override cached values, passing a command line to
change one of these values invalidates the cached configuration. running without any
options re-uses the cached configuration, which makes command line configurations
"sticky".

## tree structure -
i was originally going to try to mimic a maven project and allow other languages to be 
present (java, etc.), but decided that a separate directory is ultimately cleaner. NOTE: 
*ALL* built files are deposited in "target", so clean builds are made by removing "target".

```
source -+- (lib)
        +- (lib)
        +- (app)   --- (app.cpp)
        |
        +- (app)   -+- (app.cpp)
                    +- resources
target -+- (lib) -+- (config) -+- objects -+- *.o
        |         |            |           +- *.d
        |         |            +- (built)
        |         |
        |         +- (config) -+- objects -+- *.o
        |                      |           +- *.d
        |                      +- (built)
        |
        +- (lib) -+- (config) -+- objects -+- *.o
        |         |            |           +- *.d
        |         |            +- (built)
        |         |
        |         +- (config) -+- objects -+- *.o
        |                      |           +- *.d
        |                      +- (built)
        |
        +- (app) -+- (config) -+- objects -+- *.o
        |         |            |           +- *.d
        |         |            +- (built)
        |         |
        |         +- (config) -+- objects -+- *.o
        |                      |           +- *.d
        |                      +- (built)
        |
        +- (app) -+- (config) -+- objects -+- *.o
                  |            |           +- *.d
                  |            +- (built)
                  |            +- (copied resources)
                  |
                  +- (config) -+- objects -+- *.o
                               |           +- *.d
                               +- (built)
                               +- (copied resources)
```
