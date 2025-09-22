# mulle-semver qualify

## Overview

The `qualify` command checks if a single semantic version matches one or more semver qualifiers. It supports complex qualifier expressions including ranges, wildcards, tilde (~) and caret (^) operators, and logical combinations with AND/OR operations. This command is essential for determining if a version satisfies dependency requirements.

## Usage

```bash
mulle-semver qualify [options] <qualifiers> <version>
```

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |
| `-q`, `--quiet` | Suppress output, only return exit code |

## Exit Codes

| Exit Code | Result | Description |
|-----------|--------|-------------|
| 0 | YES | Version matches the qualifier(s) |
| 2 | NO | Version does not match the qualifier(s) |

## Examples

### Basic Qualifier Matching

```bash
# Exact version match
mulle-semver qualify "=1.2.3" "1.2.3"
# Output: YES
# Exit code: 0

mulle-semver qualify "=1.2.3" "1.2.4"
# Output: NO
# Exit code: 2
```

### Comparison Operators

```bash
# Greater than or equal
mulle-semver qualify ">=1.2.0" "1.2.3"
# Output: YES

# Less than
mulle-semver qualify "<2.0.0" "1.5.0"
# Output: YES

# Greater than
mulle-semver qualify ">1.0.0" "0.9.0"
# Output: NO
```

### Range Expressions

```bash
# Version range (inclusive)
mulle-semver qualify "1.2.0 - 1.4.0" "1.3.0"
# Output: YES

# Version range with prerelease handling
mulle-semver qualify "1.2.0 - 1.4.0" "1.3.0-beta"
# Output: YES (prerelease matches within range)
```

### Tilde (~) Operator

```bash
# Tilde allows patch-level changes
mulle-semver qualify "~1.2.3" "1.2.4"
# Output: YES

mulle-semver qualify "~1.2.3" "1.3.0"
# Output: NO

# Tilde with minor version
mulle-semver qualify "~1.2" "1.2.5"
# Output: YES

mulle-semver qualify "~1.2" "1.3.0"
# Output: NO
```

### Caret (^) Operator

```bash
# Caret allows compatible changes
mulle-semver qualify "^1.2.3" "1.5.0"
# Output: YES (minor version change allowed)

mulle-semver qualify "^1.2.3" "2.0.0"
# Output: NO (major version change not allowed)

# Caret with major version 0
mulle-semver qualify "^0.2.3" "0.2.5"
# Output: YES

mulle-semver qualify "^0.2.3" "0.3.0"
# Output: NO
```

### Wildcard Expressions

```bash
# Wildcard major version
mulle-semver qualify "1.2.x" "1.2.5"
# Output: YES

mulle-semver qualify "1.2.x" "1.3.0"
# Output: NO

# Wildcard minor version
mulle-semver qualify "1.x.x" "1.5.0"
# Output: YES

mulle-semver qualify "1.x.x" "2.0.0"
# Output: NO
```

### Logical Combinations

```bash
# AND operation (space-separated)
mulle-semver qualify ">=1.0.0 <2.0.0" "1.5.0"
# Output: YES

mulle-semver qualify ">=1.0.0 <2.0.0" "2.5.0"
# Output: NO

# OR operation (||)
mulle-semver qualify ">=2.0.0 || <1.0.0" "0.5.0"
# Output: YES

mulle-semver qualify ">=2.0.0 || <1.0.0" "1.5.0"
# Output: NO
```

### Complex Expressions

```bash
# Multiple ranges with OR
mulle-semver qualify ">=1.0.0 <1.5.0 || >=2.0.0 <2.5.0" "2.2.0"
# Output: YES

# Mixed operators
mulle-semver qualify "^1.2.0 >=1.2.3" "1.2.5"
# Output: YES

mulle-semver qualify "^1.2.0 >=1.2.3" "1.2.2"
# Output: NO
```

### Prerelease Handling

```bash
# Prerelease versions
mulle-semver qualify ">=1.0.0" "1.0.0-beta"
# Output: NO (prerelease < release)

mulle-semver qualify ">=1.0.0-beta" "1.0.0-beta.1"
# Output: YES

# Exact prerelease match
mulle-semver qualify "=1.0.0-beta" "1.0.0-beta"
# Output: YES
```

## Qualifier Syntax

### Basic Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `=` | Exact match | `=1.2.3` |
| `>` | Greater than | `>1.2.3` |
| `>=` | Greater than or equal | `>=1.2.3` |
| `<` | Less than | `<1.2.3` |
| `<=` | Less than or equal | `<=1.2.3` |
| `~` | Approximately equivalent | `~1.2.3` |
| `^` | Compatible with | `^1.2.3` |

### Advanced Syntax

| Syntax | Description | Example |
|--------|-------------|---------|
| `x.y.z - a.b.c` | Version range | `1.0.0 - 2.0.0` |
| `x.y.x` | Wildcard patch | `1.2.x` |
| `x.x.x` | Wildcard minor | `1.x.x` |
| `*.x.x` | Wildcard major | `*.2.x` |
| `expr1 expr2` | AND operation | `>=1.0.0 <2.0.0` |
| `expr1 || expr2` | OR operation | `>=2.0.0 || <1.0.0` |

## Implementation Details

### Qualifier Processing

1. **Sanitization**: Remove whitespace, handle URL fragments, normalize format
2. **Parsing**: Break down complex expressions into individual qualifiers
3. **Evaluation**: Compare version against each qualifier using semantic rules
4. **Combination**: Apply logical AND/OR operations between qualifiers

### Performance Characteristics

- **Simple qualifiers**: O(1) constant time
- **Range expressions**: O(1) per range check
- **Complex expressions**: O(n) where n is number of qualifiers
- **Memory usage**: O(m) where m is expression complexity

## Integration Examples

### Shell Scripting

```bash
#!/bin/bash

check_version() {
    local qualifier="$1"
    local version="$2"

    if mulle-semver qualify --quiet "$qualifier" "$version"; then
        echo "Version $version satisfies $qualifier"
        return 0
    else
        echo "Version $version does NOT satisfy $qualifier"
        return 1
    fi
}

# Usage
check_version ">=1.0.0 <2.0.0" "1.5.0"
check_version "^1.2.0" "1.5.0"
```

### Dependency Validation

```bash
#!/bin/bash

validate_dependencies() {
    local package_file="$1"

    while IFS=':' read -r package required_version; do
        local installed_version
        installed_version=$(get_installed_version "$package")

        if ! mulle-semver qualify --quiet "$required_version" "$installed_version"; then
            echo "ERROR: $package $installed_version does not satisfy $required_version"
            return 1
        fi
    done < "$package_file"

    echo "All dependencies satisfied"
    return 0
}

# Usage
validate_dependencies "requirements.txt"
```

### Version Compatibility Checking

```bash
#!/bin/bash

is_compatible() {
    local current="$1"
    local required="$2"

    # Check if current version is compatible with required version
    if mulle-semver qualify --quiet "$required" "$current"; then
        echo "Compatible"
        return 0
    else
        echo "Incompatible"
        return 1
    fi
}

# Check API compatibility
is_compatible "2.1.0" "^2.0.0"  # Should be compatible
is_compatible "3.0.0" "^2.0.0"  # Should be incompatible
```

### Build System Integration

```bash
#!/bin/bash

check_build_requirements() {
    local min_version="$1"
    local current_version
    current_version=$(get_build_tool_version)

    if ! mulle-semver qualify --quiet "$min_version" "$current_version"; then
        echo "Build tool version $current_version is too old. Required: $min_version"
        exit 1
    fi
}

# Check minimum tool versions
check_build_requirements ">=1.2.0"  # Node.js
check_build_requirements ">=3.8.0"   # Python
```

## Error Handling

### Invalid Qualifiers

```bash
# Malformed qualifier
mulle-semver qualify "invalid" "1.2.3"
# Error: Invalid qualifier syntax

# Empty qualifier
mulle-semver qualify "" "1.2.3"
# Error: Empty qualifier

# Invalid version
mulle-semver qualify ">=1.0.0" "not-a-version"
# Error: Invalid semantic version
```

### Edge Cases

```bash
# Zero versions
mulle-semver qualify ">=0.0.0" "0.0.0"
# Output: YES

# Very large versions
mulle-semver qualify ">=1.0.0" "999999.999999.999999"
# Output: YES

# Complex prerelease
mulle-semver qualify ">=1.0.0-beta" "1.0.0-beta.2.pre.release"
# Output: YES
```

## Use Cases

### Package Management

Used by package managers to determine if installed packages satisfy version requirements:

```bash
# Check if installed package meets requirements
mulle-semver qualify "^1.2.0" "1.5.0"  # Compatible update
mulle-semver qualify "~1.2.3" "1.2.7"  # Patch-level update
```

### CI/CD Pipelines

Validate version compatibility in automated build systems:

```bash
# Validate deployment compatibility
if mulle-semver qualify "$REQUIRED_API_VERSION" "$CURRENT_API_VERSION"; then
    deploy_application
else
    echo "API version incompatible"
    exit 1
fi
```

### Dependency Resolution

Resolve complex dependency trees with multiple version constraints:

```bash
# Multiple dependency constraints
mulle-semver qualify ">=1.0.0 <3.0.0" "$PACKAGE_VERSION" &&
mulle-semver qualify "^2.1.0" "$PACKAGE_VERSION"
```

## See Also

- **[`qualifier-type`](qualifier-type.md)** - Analyze qualifier type and scope
- **[`compare`](compare.md)** - Compare two semantic versions directly
- **[`search`](search.md)** - Search for versions matching qualifiers