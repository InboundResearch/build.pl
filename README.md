# build.pl
build.pl is an easy to use perl script that does what "make" does for C++ projects, but without any configuration needed. 

## 1. THE BASICS
### 1.1. installation
The specifics of where to install a script folder and how to add it to your path are left to the user, but you will need to add the ".../build.pl/bin" directory to your path.

build uses Bash, and build.pl uses Perl, so you will need those installed. It's tested on Perl v.5.16 and up, but requires a version with threads support, and the JSON module needs to be installed. If it's missing, you can install it with:

    > cpan JSON

#### 1.1.1. MacOS
On MacOS, I use perlbrew, which installs an unthreaded version of perl by default. You will need to install a threaded version with a command line like:
  
    > perlbrew install --as perl-5.16.0t -Dusethreads perl-5.16.0

Once Perl is installed, you will need to use CPAN to install the JSON module:

    > cpan JSON
    
I also use homebrew to install the gnu version of grep (which supports Perl-like regular expressions with the -P option). Be sure to follow the directions for 

    > brew install grep

### 1.2. quick-start
To make a basic C++ program to be compiled as an application, create a directory for your project (we'll call this the "parent" directory). Inside the parent directory, create a directory named "<your project>", and put your *.cpp file(s) in it. From a command line inside the parent directory, run `build`. The default build context will automatically compile all of the .cpp files in your project directory in a debug configuration, link them into an application named "<your project>", and then try to run the application. The default output directory is "target/<your project>". See the project under "examples/simple".

### 1.3. adding tests
Testing is a broad topic, and the build.pl approach is not to dictate the methods of testing. However, an application target in your project called "test" is treated as special, and will be the default target if it is present. See the project under "examples/simple-with-test".

The sample project uses a very basic TEST_CASE macro to build test cases that are automatically run by the program prior to calling the "main" function. I use this structure extensively in my own coding, and it has proven to be a valuable method of building unit tests without a lot of complexity, but you should be able to easily integrate other unit testing frameworks like Boost or CTest if you prefer.

### 1.4. using a more complex directory structure
If you are familiar with Java development with Apache Maven, you might prefer to put your code into a "src" directory. In order to achieve this, you will have to create a build.json file in your project's parent directory, and you will have to set a value to specify the source path name (the default value is "."). You only to to specify context variables that you want to override, so in this case it can be a very simple file:

    {
        "values": {
            "sourcePath": "src"
        }
    }

Note that build.pl doesn't support a deeply nested project structure like you find in a Java project, but this will allow you to organize your code into sub projects, break them up into libraries and applications, and include a test program. See the project under "examples/complex" to get an idea of how this can be done.

## 2. GOING DEEP
Up to this point, we've mostly been talking about how to use the "build" shell script to build your project, but you can skip this pseudo-make tool and use build.pl directly. 

### 2.1. about
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

### 2.2. requirements
What I need is to be able to start a project and go:
* Zero configuration required to start, add configuration only as needed to support increaded project complexity. 
* Build my projects, keeping the object files and targets in a separate directory from the sources (so I can organize my sources intelligently).
* Minimal structural requirements (sources must be organized in a flat directory tree), use other scripting structures to support more complex project hierarchies.
* Efficiency, using threaded operation where possible.
* Relatively platform agnostic (I'm focused on g++ right now - developing for RedHat7, Ubuntu, Debian on Raspberry Pi, MacOS, and Cygwin on Windows). 
* Support building and run one or more tests, along with the actual target application(s). 
* Use modern standards for configurations (JSON).

### 2.3. rant
It's perhaps a conversation for another day, but there is no IDE that fully delivers for C++ development in Unix environments. Eclipse with CDT is highly unstable, unfinished, and just not up to snuff when compared to state-of-the-art Java IDEs. Visual Studio Code doesn't do Intellisense with C++ in a useful way, and even my trusty IntelliJ delivers CLion, which only works for a specific type of pipeline. MacOS requires that debuggers are signed by the App Store, so CLion is the only GDB-based solution that works on that platform. XCode, while a staple of MacOS development, has a fundamentally broken windowing model, and the clang toolkit they ship is well behind the C++ standard, or the freely available clang package.

I'll acknowledge that "make" works and works well - when you have configured the makefile for your needs. But the reality is that there is no easy start to using "make". There are a few good "general purpose" C++ makefiles if you hunt around on StackOverflow, but you are really on your own if you don't already have a makefile. You have to learn "make" just like any other form of programming language, and once you get past the basic capabilities of checking dependencies, "make" gets hard to use. You quickly find yourself wishing you could just write a shell script, instead.

The "state of the art" is CMake, a tool with an obtuse syntax of its own that builds hyper-complex makefiles for you, and loosely integrates a relatively small ecosystem of testing tools. It's a good start, but is more meant to solve the portability problem than the build problem.


### 2.4. build configuration files:
Build configuration files in json format, called "build.json", are read at multiple levels. The first default is in the build script binary directory and contains global defaults. The second default is at the root of the project directory, and the final build configuration can be found inside each individual target. Each variable requested is processed to the lowest level configuration in which it is found, so that most defaults can be specified at the root config level, and overridden at the lower levels if necessary, possibly using the parent value in its redefinition. Configuration variables can also be redefined at the command line.

example build.json:

    {
        "values": {
            "type": "staticLibrary",
            "dependencies":[],
        },
        "configurations": {
            "debug": {
                "compilerOptions": "-g -D_DEBUG_"
            },
            "release": {
                "compilerOptions": "-O3 -D_NDEBUG_"
            }
        }
    }

### 2.5. target names:
Source directory names are used for the final product name (e.g. directory "math" builds a target called "math"). This cannot be overridden.

### 2.6. variables:
Configuration variables are a "$" followed by any valid camel-case identifiers:

`$[a-z][A-Za-z0-9]+`

configuration variables are mostly defined statically, but can be specified to be
interpreted by a shell or by variable replacement:

1)  `$[name]` is a simple replacement from the current build configuration dictionary.
   if `[name]` is not a known build configuration variable, it is left unchanged. if
   the replacement value is "*" or is not a simple scalar (in JSON), it is left unchanged.

2)  a `$([command])` construct replaces the string with the value returned by a shell
  executing the given command.

3)  TODO: a `?([ifdef]:[ifndef])` structure in a variable value declares a conditional
   definition, where the ifdef side is executed if the variable is already defined, and
   the ifndef side is executed if it is not. omitting the ":" is valid if there is no
   ifndef. omitting the ifdef is equivalent to un-defining the value, so erasing a
   setting is "?()". a simple "$" before the ":" is sufficient to indicate the existing
   value, but complex redefinitions should use the variable name normally.

4)  TODO: a `!` at the beginning of a variable value declares it to be "final", and no further
   overrides will be processed.

## 2.7. build configuration hierarchy:
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

### 2.8. dependencies:
targets (library or application) might depend on another target being built first, so
dependencies can be named in the array variable "dependencies". the include paths sent
to the compiler will include the dependency directories as -I includes, and the library
paths sent to the linker will include the dependency directories as -L libs.

another option would be to reference all external includes with a relative path,
i.e. `#include "common/Types.h"`

### 2.9. command line options:
Command line options can be used to override build configuration settings. In practice, the only settings allowed are "target" and "configuration". This effect is achieved by processing the command line opetions as a build context after the project-level context.

NOTE - other build configuration variable values are too complicated to support from the command line. They may be specified, but the result is undefined and unsupported, and might be subject to later revision.

### 2.10. tree structure -
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

## 3. TODO
* copy resources
* ensure runnable code when building with shared libraries in linux (this works in MacOS without any special handling)
* figure out how to build shared libraries on cygwin, maybe have to add a "platforms" object in the context, and set that appropriately based on a `uname -s` call? something informed by this:
```
unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac
echo ${machine}
```

