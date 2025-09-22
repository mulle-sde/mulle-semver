# mulle-semver parse

## Overview

The `parse` command parses semantic version strings and extracts their constituent parts. It can handle both strict and lenient parsing modes, and provides output in various formats for different use cases.

## Usage

```bash
mulle-semver parse [options] <version>+
```

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |
| `-q`, `--quiet` | Only return parse status (0=OK) |
| `-l`, `--lenient` | Use lenient parser (allows versions like "1.0" or "1") |
| `--raw` | Output as shell script variables (default) |
| `--cooked` | Print as version number |
| `--pretty` | Format output nicely (default for cooked mode) |
| `--no-pretty` | Raw output without formatting |

## Examples

### Basic Parsing

```bash
# Parse a standard semantic version
mulle-semver parse "1.2.3"
# Output: _major=1;_minor=2;_patch=3;_prerelease=;_build=

# Parse with prerelease and build metadata
mulle-semver parse "1.2.3-alpha.1+build.456"
# Output: _major=1;_minor=2;_patch=3;_prerelease=alpha.1;_build=build.456
```

### Lenient Parsing

```bash
# Parse version with missing patch (lenient mode)
mulle-semver parse --lenient "1.2"
# Output: _major=1;_minor=2;_patch=0;_prerelease=;_build=

# Parse major version only (lenient mode)
mulle-semver parse --lenient "1"
# Output: _major=1;_minor=0;_patch=0;_prerelease=;_build=
```

### Cooked Output

```bash
# Get formatted version output
mulle-semver parse --cooked "1.2.3-alpha.1+build.456"
# Output: 1.2.3-alpha.1+build.456

# Parse multiple versions
mulle-semver parse --cooked "1.0.0" "2.0.0-beta" "3.0.0+build.123"
# Output:
# 1.0.0
# 2.0.0-beta
# 3.0.0+build.123
```

### Quiet Mode

```bash
# Check if version is valid (quiet mode)
mulle-semver parse --quiet "1.2.3"
echo $?  # Returns 0 for valid

mulle-semver parse --quiet "invalid.version"
echo $?  # Returns 1 for invalid
```

## Output Formats

### Raw Mode (Default)

Outputs shell script variable assignments that can be evaluated:

```bash
eval "$(mulle-semver parse "1.2.3-alpha.1+build.456")"
echo "Version: ${_major}.${_minor}.${_patch}"
echo "Prerelease: ${_prerelease}"
echo "Build: ${_build}"
```

### Cooked Mode

Outputs formatted version strings:

```bash
mulle-semver parse --cooked "1.2.3-alpha.1+build.456"
# Output: 1.2.3-alpha.1+build.456
```

## Version Components

The parser extracts the following components from a semantic version:

- **Major**: The major version number (required)
- **Minor**: The minor version number (required)
- **Patch**: The patch version number (required, but can be 0 in lenient mode)
- **Prerelease**: Optional prerelease identifier (e.g., "alpha.1", "beta.2")
- **Build**: Optional build metadata (e.g., "build.456", "2019-01-01")

## Supported Version Formats

### Standard Semantic Versions

```bash
1.2.3
1.2.3-alpha
1.2.3-alpha.1
1.2.3+build.456
1.2.3-alpha.1+build.456
```

### Lenient Versions (with --lenient)

```bash
1.2      # Missing patch, treated as 1.2.0
1        # Missing minor and patch, treated as 1.0.0
1.0      # Missing patch, treated as 1.0.0
```

### Version Prefixes

```bash
v1.2.3   # 'v' prefix is automatically stripped
V1.2.3   # 'V' prefix is automatically stripped
```

## Error Handling

### Invalid Versions

```bash
# Missing required components
mulle-semver parse "1.2"  # Error: Expected version triple

# Leading zeros in numeric parts
mulle-semver parse "1.02.3"  # Error: Leading zero not allowed

# Invalid prerelease identifiers
mulle-semver parse "1.2.3-01"  # Error: Leading zero in prerelease
```

### Lenient Mode Errors

Even in lenient mode, some formats are invalid:

```bash
# Empty string
mulle-semver parse --lenient ""  # Error: No version provided

# Non-numeric components
mulle-semver parse --lenient "a.b.c"  # Error: Non-numeric version parts
```

## Integration Examples

### Shell Scripting

```bash
#!/bin/bash

parse_version() {
    local version="$1"
    eval "$(mulle-semver parse "$version")"

    echo "Parsed version: $version"
    echo "  Major: $_major"
    echo "  Minor: $_minor"
    echo "  Patch: $_patch"
    echo "  Prerelease: $_prerelease"
    echo "  Build: $_build"
}

parse_version "2.1.0-beta.1+build.123"
```

### Version Validation

```bash
#!/bin/bash

is_valid_version() {
    mulle-semver parse --quiet "$1" >/dev/null 2>&1
}

if is_valid_version "$VERSION"; then
    echo "Valid semantic version: $VERSION"
else
    echo "Invalid semantic version: $VERSION"
fi
```

### Batch Processing

```bash
#!/bin/bash

# Parse multiple versions from a file
while IFS= read -r version; do
    if mulle-semver parse --quiet "$version" >/dev/null 2>&1; then
        echo "✓ $version"
    else
        echo "✗ $version"
    fi
done < versions.txt
```

## See Also

- **[`compare`](compare.md)** - Compare two semantic versions
- **[`numeric-compare`](numeric-compare.md)** - Compare numeric parts only
- **[`alphanumeric-compare`](alphanumeric-compare.md)** - Compare alphanumeric parts only