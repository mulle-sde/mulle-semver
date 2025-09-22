# mulle-semver compare

## Overview

The `compare` command compares two semantic version strings and outputs the comparison result. It returns one of three possible outcomes: ASCENDING, DESCENDING, or SAME, along with corresponding exit codes that can be used in shell scripts.

## Usage

```bash
mulle-semver compare [options] <version1> <version2>
```

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |
| `-q`, `--quiet` | Suppress output, only return exit code |
| `-l`, `--lenient` | Use lenient parser (allows versions like "1.0" or "1") |

## Exit Codes

| Exit Code | Result | Description |
|-----------|--------|-------------|
| 0 | SAME | Versions are identical |
| 60 | ASCENDING | First version is less than second version |
| 62 | DESCENDING | First version is greater than second version |

## Examples

### Basic Comparison

```bash
# Compare two versions
mulle-semver compare "1.2.3" "1.3.0"
# Output: ASCENDING
# Exit code: 60

mulle-semver compare "2.0.0" "1.9.9"
# Output: DESCENDING
# Exit code: 62

mulle-semver compare "1.2.3" "1.2.3"
# Output: SAME
# Exit code: 0
```

### Quiet Mode

```bash
# Use exit codes for scripting
if mulle-semver compare --quiet "1.2.3" "1.3.0"; then
    echo "Versions are equal"
elif [ $? -eq 60 ]; then
    echo "First version is older"
elif [ $? -eq 62 ]; then
    echo "First version is newer"
fi
```

### Prerelease Comparison

```bash
# Prerelease versions comparison
mulle-semver compare "1.0.0-alpha" "1.0.0-beta"
# Output: ASCENDING (alpha < beta)

mulle-semver compare "1.0.0-beta.2" "1.0.0-beta.10"
# Output: ASCENDING (numeric comparison)

mulle-semver compare "1.0.0-rc.1" "1.0.0"
# Output: ASCENDING (prerelease < release)
```

### Build Metadata Handling

```bash
# Build metadata is ignored in comparison
mulle-semver compare "1.2.3+build.123" "1.2.3+build.456"
# Output: SAME (build metadata ignored)

mulle-semver compare "1.2.3+build.123" "1.2.4+build.456"
# Output: ASCENDING (only version numbers matter)
```

## Comparison Rules

### Semantic Versioning Rules

The comparison follows the official semantic versioning specification:

1. **Major, Minor, Patch**: Numeric comparison in order
   - `1.2.3` < `1.3.0` < `2.0.0`

2. **Prerelease Identifiers**: Compared after version numbers
   - `1.0.0-alpha` < `1.0.0-beta` < `1.0.0-rc` < `1.0.0`

3. **Prerelease Numeric Parts**: Numeric comparison
   - `1.0.0-beta.1` < `1.0.0-beta.2` < `1.0.0-beta.10`

4. **Prerelease Alphanumeric Parts**: Lexical comparison
   - `1.0.0-alpha` < `1.0.0-beta` < `1.0.0-gamma`

5. **Build Metadata**: Completely ignored in comparison
   - `1.2.3+build.123` ≡ `1.2.3+build.456`

### Special Cases

```bash
# Same version with different prerelease
mulle-semver compare "1.0.0-alpha.1" "1.0.0-alpha.2"
# Output: ASCENDING

# Release vs prerelease of same version
mulle-semver compare "1.0.0-rc.1" "1.0.0"
# Output: ASCENDING (prerelease < release)

# Different major versions
mulle-semver compare "1.9.9" "2.0.0"
# Output: ASCENDING
```

## Integration Examples

### Shell Scripting

```bash
#!/bin/bash

version_compare() {
    local v1="$1"
    local v2="$2"

    if mulle-semver compare --quiet "$v1" "$v2" >/dev/null 2>&1; then
        echo "equal"
        return 0
    fi

    case $? in
        60) echo "less"; return 60 ;;
        62) echo "greater"; return 62 ;;
        *) echo "error"; return 1 ;;
    esac
}

# Usage
result=$(version_compare "1.2.3" "1.3.0")
echo "1.2.3 is $result than 1.3.0"
```

### Version Validation

```bash
#!/bin/bash

is_newer_version() {
    local current="$1"
    local candidate="$2"

    if mulle-semver compare --quiet "$candidate" "$current" >/dev/null 2>&1; then
        return 1  # Same version
    fi

    [ $? -eq 62 ]  # Return true if candidate > current
}

if is_newer_version "1.2.3" "1.3.0"; then
    echo "New version available: 1.3.0"
fi
```

### Sorting Versions

```bash
#!/bin/bash

sort_versions() {
    # Read versions from stdin, sort them
    local versions=()
    while IFS= read -r version; do
        versions+=("$version")
    done

    # Simple bubble sort using version comparison
    local n=${#versions[@]}
    for ((i = 0; i < n; i++)); do
        for ((j = 0; j < n - i - 1; j++)); do
            if mulle-semver compare --quiet "${versions[j]}" "${versions[j+1]}" >/dev/null 2>&1; then
                continue
            elif [ $? -eq 62 ]; then
                # Swap if out of order
                temp="${versions[j]}"
                versions[j]="${versions[j+1]}"
                versions[j+1]="$temp"
            fi
        done
    done

    printf '%s\n' "${versions[@]}"
}

# Usage
echo -e "1.10.0\n1.2.0\n1.3.0\n1.1.0" | sort_versions
```

### Dependency Checking

```bash
#!/bin/bash

check_dependency_version() {
    local required="$1"
    local installed="$2"

    if mulle-semver compare --quiet "$installed" "$required" >/dev/null 2>&1; then
        echo "✓ Dependency satisfied: $installed >= $required"
        return 0
    elif [ $? -eq 60 ]; then
        echo "✗ Dependency not satisfied: $installed < $required"
        return 1
    else
        echo "✓ Dependency satisfied: $installed > $required"
        return 0
    fi
}

check_dependency_version "1.2.0" "1.3.1"
check_dependency_version "2.0.0" "1.9.9"
```

## Error Handling

### Invalid Versions

```bash
# Invalid first version
mulle-semver compare "invalid" "1.2.3"
# Error: Expected version triple at start of "invalid"

# Invalid second version
mulle-semver compare "1.2.3" "not-a-version"
# Error: Expected version triple at start of "not-a-version"

# Both versions invalid
mulle-semver compare "bad" "worse"
# Error: Expected version triple at start of "bad"
```

### Lenient Mode

```bash
# Lenient parsing allows shorter versions
mulle-semver compare --lenient "1.2" "1.3"
# Output: ASCENDING (compares 1.2.0 vs 1.3.0)

mulle-semver compare --lenient "1" "2"
# Output: ASCENDING (compares 1.0.0 vs 2.0.0)
```

## Performance Considerations

- The comparison is optimized for performance and can handle large version numbers
- For sorting large lists of versions, consider using the dedicated `sort` command
- Build metadata is ignored during comparison for efficiency

## See Also

- **[`parse`](parse.md)** - Parse semantic version strings
- **[`numeric-compare`](numeric-compare.md)** - Compare numeric parts only
- **[`alphanumeric-compare`](alphanumeric-compare.md)** - Compare alphanumeric parts only
- **[`sort`](sort.md)** - Sort multiple semantic versions