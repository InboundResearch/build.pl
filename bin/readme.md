# build.pl
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