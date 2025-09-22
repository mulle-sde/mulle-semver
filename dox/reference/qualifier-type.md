# mulle-semver qualifier-type

## Overview

The `qualifier-type` command analyzes semver qualifiers to determine their scope and matching behavior. It categorizes qualifiers into different types (EMPTY, NO, SEMVER, SINGLE, MULTI) based on their syntax and semantic meaning. This command is essential for understanding how qualifiers will behave in version matching operations and for validating qualifier syntax.

## Usage

```bash
mulle-semver qualifier-type [options] <qualifier>
```

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |
| `-q`, `--quiet` | Only return exit code, suppress output |

## Exit Codes

| Exit Code | Type | Description |
|-----------|------|-------------|
| 48 | EMPTY | Qualifier is empty or contains only whitespace |
| 49 | NO | Not a valid semver qualifier |
| 50 | SEMVER | Exact semantic version (matches one version) |
| 52 | SINGLE | Matches at most one version |
| 53 | MULTI | May match multiple versions |

## Examples

### Basic Type Classification

```bash
# Empty qualifier
mulle-semver qualifier-type ""
# Output: EMPTY
# Exit code: 48

# Invalid qualifier
mulle-semver qualifier-type "invalid"
# Output: NO
# Exit code: 49

# Exact version
mulle-semver qualifier-type "1.2.3"
# Output: SEMVER
# Exit code: 50

# Single version match
mulle-semver qualifier-type "=1.2.3"
# Output: SINGLE
# Exit code: 52

# Multiple version match
mulle-semver qualifier-type ">=1.0.0"
# Output: MULTI
# Exit code: 53
```

### Comparison Operators

```bash
# Equality (single match)
mulle-semver qualifier-type "=1.2.3"
# Output: SINGLE

# Greater than (multiple matches)
mulle-semver qualifier-type ">1.2.3"
# Output: MULTI

# Less than or equal (multiple matches)
mulle-semver qualifier-type "<=2.0.0"
# Output: MULTI

# Range (multiple matches)
mulle-semver qualifier-type ">=1.0.0 <2.0.0"
# Output: MULTI
```

### Wildcard Patterns

```bash
# Wildcard patch version
mulle-semver qualifier-type "1.2.x"
# Output: MULTI

# Wildcard minor version
mulle-semver qualifier-type "1.x.x"
# Output: MULTI

# Wildcard major version
mulle-semver qualifier-type "*.x.x"
# Output: MULTI
```

### Tilde and Caret Operators

```bash
# Tilde operator
mulle-semver qualifier-type "~1.2.3"
# Output: MULTI

# Caret operator
mulle-semver qualifier-type "^1.2.3"
# Output: MULTI

# Caret with major version 0
mulle-semver qualifier-type "^0.2.3"
# Output: MULTI
```

### Logical Combinations

```bash
# AND combination
mulle-semver qualifier-type ">=1.0.0 <2.0.0"
# Output: MULTI

# OR combination
mulle-semver qualifier-type ">=2.0.0 || <1.0.0"
# Output: MULTI

# Complex expression
mulle-semver qualifier-type "^1.2.0 >=1.2.3"
# Output: MULTI
```

### Prerelease Qualifiers

```bash
# Prerelease version
mulle-semver qualifier-type "1.0.0-beta"
# Output: SEMVER

# Prerelease with operator
mulle-semver qualifier-type ">=1.0.0-beta"
# Output: MULTI
```

## Qualifier Types Explained

### EMPTY (48)
Qualifiers that are empty or contain only whitespace after normalization.

```bash
mulle-semver qualifier-type ""
mulle-semver qualifier-type "   "
mulle-semver qualifier-type "	"  # tab
```

### NO (49)
Strings that are not valid semver qualifiers.

```bash
mulle-semver qualifier-type "not-a-version"
mulle-semver qualifier-type "1.2"          # missing patch
mulle-semver qualifier-type "1.2.3.4"      # too many parts
mulle-semver qualifier-type "1.2.3-beta@"  # invalid prerelease
```

### SEMVER (50)
Exact semantic version strings without operators.

```bash
mulle-semver qualifier-type "1.2.3"
mulle-semver qualifier-type "1.0.0-beta"
mulle-semver qualifier-type "2.0.0-rc.1+build.1"
```

### SINGLE (52)
Qualifiers that can match at most one version.

```bash
mulle-semver qualifier-type "=1.2.3"
mulle-semver qualifier-type "=1.0.0-beta"
```

### MULTI (53)
Qualifiers that can match multiple versions.

```bash
mulle-semver qualifier-type ">1.2.3"
mulle-semver qualifier-type ">=1.0.0"
mulle-semver qualifier-type "<2.0.0"
mulle-semver qualifier-type "<=1.5.0"
mulle-semver qualifier-type ">=1.0.0 <2.0.0"
mulle-semver qualifier-type "^1.2.3"
mulle-semver qualifier-type "~1.2.3"
mulle-semver qualifier-type "1.2.x"
mulle-semver qualifier-type ">=2.0.0 || <1.0.0"
```

## Quiet Mode

Use quiet mode to suppress output and only check exit codes:

```bash
# Check if qualifier is valid (not NO or EMPTY)
if [ $(mulle-semver qualifier-type --quiet "$QUALIFIER") -ge 50 ]; then
    echo "Valid qualifier"
else
    echo "Invalid qualifier"
fi

# Check if qualifier matches multiple versions
if [ $(mulle-semver qualifier-type --quiet "$QUALIFIER") -eq 53 ]; then
    echo "Multi-match qualifier"
fi
```

## Integration Examples

### Shell Scripting

```bash
#!/bin/bash

validate_qualifier() {
    local qualifier="$1"

    case $(mulle-semver qualifier-type --quiet "$qualifier") in
        48)
            echo "ERROR: Empty qualifier"
            return 1
            ;;
        49)
            echo "ERROR: Invalid qualifier syntax"
            return 1
            ;;
        50)
            echo "INFO: Exact version qualifier"
            ;;
        52)
            echo "INFO: Single match qualifier"
            ;;
        53)
            echo "INFO: Multi-match qualifier"
            ;;
    esac

    return 0
}

# Usage
validate_qualifier ">=1.0.0 <2.0.0"
```

### Dependency Validation

```bash
#!/bin/bash

check_dependency_constraints() {
    local constraints_file="$1"

    while IFS=':' read -r package constraint; do
        if ! mulle-semver qualifier-type --quiet "$constraint" >/dev/null; then
            echo "ERROR: Invalid constraint '$constraint' for package $package"
            return 1
        fi

        # Check if constraint is too broad
        if [ $(mulle-semver qualifier-type --quiet "$constraint") -eq 53 ]; then
            echo "WARNING: Broad constraint '$constraint' for package $package"
        fi
    done < "$constraints_file"

    echo "All constraints validated"
    return 0
}
```

### Version Resolution Strategy

```bash
#!/bin/bash

choose_resolution_strategy() {
    local constraint="$1"

    case $(mulle-semver qualifier-type --quiet "$constraint") in
        50)
            echo "Use exact version matching"
            ;;
        52)
            echo "Use single version resolution"
            ;;
        53)
            echo "Use latest/highest version resolution"
            ;;
        *)
            echo "ERROR: Invalid constraint"
            return 1
            ;;
    esac
}

# Usage
STRATEGY=$(choose_resolution_strategy "^1.2.0")
```

### Package Registry Validation

```bash
#!/bin/bash

validate_package_metadata() {
    local package_json="$1"

    # Extract version constraints from package.json
    local dependencies
    dependencies=$(jq -r '.dependencies // {} | to_entries[] | "\(.key):\(.value)"' "$package_json")

    echo "$dependencies" | while IFS=':' read -r package constraint; do
        if [ $(mulle-semver qualifier-type --quiet "$constraint") -eq 49 ]; then
            echo "ERROR: Invalid version constraint '$constraint' for $package"
            return 1
        fi
    done

    echo "Package metadata validation passed"
    return 0
}
```

### CI/CD Pipeline Integration

```bash
#!/bin/bash

validate_release_qualifier() {
    local version="$1"
    local qualifier="$2"

    # Check if version matches qualifier
    if mulle-semver qualify --quiet "$qualifier" "$version"; then
        echo "✅ Version $version matches qualifier $qualifier"
        return 0
    else
        echo "❌ Version $version does NOT match qualifier $qualifier"
        return 1
    fi
}

# Usage in CI pipeline
RELEASE_VERSION="1.2.3"
REQUIRED_QUALIFIER=">=1.0.0 <2.0.0"

if ! validate_release_qualifier "$RELEASE_VERSION" "$REQUIRED_QUALIFIER"; then
    echo "Release validation failed"
    exit 1
fi
```

## Error Handling

### Invalid Qualifiers

```bash
# Malformed version
mulle-semver qualifier-type "1.2"
# Output: NO

# Invalid prerelease
mulle-semver qualifier-type "1.2.3-beta@invalid"
# Output: NO

# Invalid operator
mulle-semver qualifier-type "==1.2.3"
# Output: NO
```

### Edge Cases

```bash
# Leading/trailing whitespace (normalized)
mulle-semver qualifier-type " >=1.0.0 "
# Output: MULTI

# Multiple spaces (normalized)
mulle-semver qualifier-type ">=1.0.0  <2.0.0"
# Output: MULTI

# Empty after normalization
mulle-semver qualifier-type "   "
# Output: EMPTY
```

## Performance Characteristics

### Analysis Complexity

- **EMPTY/NO**: O(1) constant time
- **SEMVER**: O(n) where n is version string length
- **SINGLE**: O(n) parsing time
- **MULTI**: O(m) where m is expression complexity

### Memory Usage

- Minimal memory footprint
- No external dependencies for analysis
- String processing only

## Use Cases

### Package Manager Validation

Validate version constraints in package definitions:

```bash
# Validate package.json constraints
jq -r '.dependencies // {} | to_entries[] | .value' package.json | \
while read -r constraint; do
    mulle-semver qualifier-type "$constraint" >/dev/null || \
        echo "Invalid constraint: $constraint"
done
```

### Dependency Resolution

Choose appropriate resolution algorithms based on qualifier type:

```bash
case $(mulle-semver qualifier-type --quiet "$constraint") in
    50) resolve_exact_version "$constraint" ;;
    52) resolve_single_version "$constraint" ;;
    53) resolve_latest_version "$constraint" ;;
esac
```

### Security Auditing

Check for overly broad version constraints:

```bash
# Flag broad constraints
if [ $(mulle-semver qualifier-type --quiet "$constraint") -eq 53 ]; then
    echo "WARNING: Broad constraint may include vulnerable versions"
fi
```

### Documentation Generation

Generate constraint type information for documentation:

```bash
# Document constraint types
echo "# Version Constraints" > constraints.md
echo "| Constraint | Type |" >> constraints.md
echo "|------------|------|" >> constraints.md

while read -r constraint; do
    type=$(mulle-semver qualifier-type "$constraint")
    echo "| $constraint | $type |" >> constraints.md
done < constraints.txt
```

## See Also

- **[`qualify`](qualify.md)** - Test if versions match qualifiers
- **[`search`](search.md)** - Search for versions matching qualifiers
- **[`compare`](compare.md)** - Compare two semantic versions