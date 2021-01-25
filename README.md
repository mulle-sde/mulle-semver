# mulle-semver

#### 📍 mulle-semver semantic versioning tool

This is most of npm's [semver]() functionality reimplemented in bash. Other
it being in bash there are no advantages to mulle-semver over npm semver.

The commandline interface is also different. It's intended function is not
as a standalone tool, but as a library for [mulle-fetch](//github.com/mulle-)


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

Compares two arbitrarily large strings by the numeric value. Except for a
single zero, numbers may not have a leading 0.


### qualify <qualifier> <version>

```
mulle-semver qualify '>=1.3.0 <1.4.0' 1.2.23
```

Check a semver version against a semver qualifier. Checkout the documentation on
[semver ranges](https://www.npmjs.com/package/semver) for what is possible.

Often used qualifiers operators are
```


### compare

```
mulle-semver compare 1.3.0 1.2.23
```

Compares two semver qualifiers.


### compare


```
mulle-semver parse 1.3.0
```

Checks if a version is semver compatible. Outputs it, if yes.


### search

```
mulle-semver search '>=1.2.0' 1.1.0 1.2.0 1.3.0
```

Searches through a list of versions for the best matching value, which is the
highest version that fits the qualifier.


## Build

This is a [mulle-sde](https://mulle-sde.github.io/) project.

It comes with its own virtual environment and list of dependencies.
To fetch and build everything say:

```
mulle-sde craft
```
