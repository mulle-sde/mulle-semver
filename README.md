# 📍 semantic versioning tool

... for Android, BSDs, Linux, macOS, SunOS, Windows (MinGW, WSL)

This is most of npm's [semver](//docs.npmjs.com/cli/v6/using-npm/semver/)
functionality reimplemented in bash (up to but not including "Functions").
Besides it being written in bash, there are no advantages of mulle-semver over
npm semver.

The commandline interface is also different. It's primary use is not
as a standalone tool, but as a library for
[mulle-fetch](//github.com/mulle-sde/mulle-fetch).

| Release Version                                       | Release Notes
|-------------------------------------------------------|--------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/mulle-sde/mulle-semver.svg)  | [RELEASENOTES](RELEASENOTES.md) |





## Commands

### alphanumeric-compare

```
mulle-semver alphanumeric-compare "VfL" "Bochum 1848"
```

Compares two arbitrarily large strings by ASCII value.


### numeric-compare

```
mulle-semver numeric-compare 123 124
```

Compares two arbitrarily large strings by their numeric value. Except for a
single zero, numbers may not have a leading 0.


### qualify <qualifier> <version>

```
mulle-semver qualify '>=1.3.0 <1.4.0' 1.2.23
```

Check a semver version against a semver qualifier. Checkout the documentation on
[semver ranges](https://www.npmjs.com/package/semver) for what is possible.


### compare

```
mulle-semver compare 1.3.0 1.2.23
```

Compares two semver qualifiers.


### parse


```
mulle-semver parse 1.3.0
```

Checks if a version is semver compatible.


### search

```
mulle-semver search '>=1.2.0' 1.1.0 1.2.0 1.3.0
```

Searches through a list of versions for the best matching value, which is the
highest version that fits the qualifier.







## Add





### Add  as a cmake subproject

In your code include its header:

``` c
#include </.h>
```

Add  and dependencies as git submodules and link against
them:

``` bash
git submodule add -f --name "" \
                        "https://github.com//" \
                        "stash/"
git submodule update --init --recursive
```

``` cmake
include_directories( SYSTEM "${CMAKE_BINARY_DIR}/include")

add_subdirectory( stash/)
add_subdirectory( stash/)

target_link_libraries( ${PROJECT_NAME} PUBLIC )
target_link_libraries( ${PROJECT_NAME} PUBLIC )
```

Or let [mulle-sde](//github.com/mulle-sde) do it:

``` sh
mulle-sde add github:/
```

## Install

See [mulle-sde-developer](//github.com/mulle-sde/mulle-sde-developer) how to
install mulle-sde, which will also install mulle-semver with required
dependencies.

The command to install only the latest mulle-semver into
`/usr/local` (with **sudo**) is:

``` bash
curl -L 'https://github.com/mulle-sde/mulle-semver/archive/latest.tar.gz' \
 | tar xfz - && cd 'mulle-semver-latest' && sudo ./bin/installer /usr/local
```



## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK


