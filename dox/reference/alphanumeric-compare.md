# mulle-semver alphanumeric-compare

## Overview

The `alphanumeric-compare` command compares two alphanumeric strings according to semantic versioning rules. It uses C locale collation for consistent, ASCII-based sorting and supports wildcard matching. This command is primarily used for comparing prerelease identifiers and other alphanumeric components of semantic versions.

## Usage

```bash
mulle-semver alphanumeric-compare [options] <string1> <string2>
```

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |
| `-q`, `--quiet` | Suppress output, only return exit code |

## Exit Codes

| Exit Code | Result | Description |
|-----------|--------|-------------|
| 0 | SAME | Strings are identical |
| 60 | ASCENDING | First string comes before second string |
| 62 | DESCENDING | First string comes after second string |

## Examples

### Basic Alphanumeric Comparison

```bash
# Compare simple strings
mulle-semver alphanumeric-compare "alpha" "beta"
# Output: ASCENDING
# Exit code: 60

mulle-semver alphanumeric-compare "beta" "alpha"
# Output: DESCENDING
# Exit code: 62

mulle-semver alphanumeric-compare "gamma" "gamma"
# Output: SAME
# Exit code: 0
```

### Prerelease Identifier Comparison

```bash
# Compare prerelease identifiers
mulle-semver alphanumeric-compare "alpha" "beta"
# Output: ASCENDING (alpha < beta)

mulle-semver alphanumeric-compare "rc" "beta"
# Output: DESCENDING (rc > beta)

mulle-semver alphanumeric-compare "alpha.1" "alpha.2"
# Output: ASCENDING (lexicographic comparison)
```

### Mixed Alphanumeric Comparison

```bash
# Compare strings with numbers and letters
mulle-semver alphanumeric-compare "beta10" "beta2"
# Output: ASCENDING (beta10 < beta2 in ASCII)

mulle-semver alphanumeric-compare "v1" "v10"
# Output: DESCENDING (v1 > v10 in ASCII)

mulle-semver alphanumeric-compare "rc1" "rc01"
# Output: DESCENDING (rc1 > rc01 in ASCII)
```

### Wildcard Support

```bash
# Wildcards match any value
mulle-semver alphanumeric-compare "alpha" "*"
# Output: SAME
# Exit code: 0

mulle-semver alphanumeric-compare "*" "beta"
# Output: SAME
# Exit code: 0

mulle-semver alphanumeric-compare "*" "*"
# Output: SAME
# Exit code: 0
```

### Quiet Mode

```bash
# Use exit codes for scripting
if mulle-semver alphanumeric-compare --quiet "alpha" "beta"; then
    echo "Strings are identical"
elif [ $? -eq 60 ]; then
    echo "First string comes first"
elif [ $? -eq 62 ]; then
    echo "Second string comes first"
fi
```

## Comparison Rules

### ASCII Collation

The comparison uses C locale collation, which follows ASCII ordering:

1. **Control characters** (0-31) come first
2. **Space character** (32)
3. **Punctuation and symbols** (33-47, 58-64, 91-96, 123-126)
4. **Digits** (48-57): '0' < '1' < ... < '9'
5. **Uppercase letters** (65-90): 'A' < 'B' < ... < 'Z'
6. **Lowercase letters** (97-122): 'a' < 'b' < ... < 'z'
7. **More symbols** (123-126)

### Special Cases

```bash
# Case sensitivity
mulle-semver alphanumeric-compare "Alpha" "alpha"
# Output: ASCENDING (uppercase comes before lowercase)

# Numbers vs letters
mulle-semver alphanumeric-compare "123" "abc"
# Output: ASCENDING (digits come before letters)

# Symbols vs alphanumeric
mulle-semver alphanumeric-compare "-test" "test"
# Output: ASCENDING (hyphen comes before letters)
```

## Implementation Details

### C Locale Usage

The command temporarily sets the `LC_ALL` environment variable to 'C' to ensure consistent collation across different systems:

```bash
old="${LC_ALL}"
LC_ALL='C'
# Perform comparison
LC_ALL="${old}"
```

This guarantees that the comparison results are identical regardless of the system's locale settings.

### Performance Characteristics

- **Simple strings**: O(n) where n is the length of the shorter string
- **Wildcards**: O(1) constant time
- **Memory usage**: O(1) additional space beyond input strings
- **Locale switching**: Minimal overhead due to temporary LC_ALL modification

## Integration Examples

### Shell Scripting

```bash
#!/bin/bash

alphanumeric_compare() {
    local s1="$1"
    local s2="$2"

    if mulle-semver alphanumeric-compare --quiet "$s1" "$s2" >/dev/null 2>&1; then
        echo "equal"
        return 0
    fi

    case $? in
        60) echo "first"; return 60 ;;
        62) echo "second"; return 62 ;;
        *) echo "error"; return 1 ;;
    esac
}

# Usage
result=$(alphanumeric_compare "alpha" "beta")
echo "alpha comes $result in sort order"
```

### Prerelease Version Sorting

```bash
#!/bin/bash

sort_prerelease_identifiers() {
    # Read identifiers from stdin, sort them
    local identifiers=()
    while IFS= read -r id; do
        identifiers+=("$id")
    done

    # Simple bubble sort using alphanumeric comparison
    local n=${#identifiers[@]}
    for ((i = 0; i < n; i++)); do
        for ((j = 0; j < n - i - 1; j++)); do
            if mulle-semver alphanumeric-compare --quiet "${identifiers[j]}" "${identifiers[j+1]}" >/dev/null 2>&1; then
                continue
            elif [ $? -eq 62 ]; then
                # Swap if out of order
                temp="${identifiers[j]}"
                identifiers[j]="${identifiers[j+1]}"
                identifiers[j+1]="$temp"
            fi
        done
    done

    printf '%s\n' "${identifiers[@]}"
}

# Usage - sort prerelease identifiers
echo -e "gamma\nbeta\nalpha" | sort_prerelease_identifiers
```

### Semantic Version Component Comparison

```bash
#!/bin/bash

compare_prerelease_parts() {
    local part1="$1"
    local part2="$2"

    # Extract alphanumeric parts from prerelease identifiers
    local alpha1=$(echo "$part1" | sed 's/[0-9]*//g')
    local alpha2=$(echo "$part2" | sed 's/[0-9]*//g')

    if [ -z "$alpha1" ] && [ -z "$alpha2" ]; then
        echo "both numeric"
        return 0
    fi

    alphanumeric_compare "$alpha1" "$alpha2"
}

# Compare prerelease components
compare_prerelease_parts "alpha" "beta"    # alpha < beta
compare_prerelease_parts "rc" "beta"       # rc > beta
```

### Build Metadata Comparison

```bash
#!/bin/bash

compare_build_metadata() {
    local meta1="$1"
    local meta2="$2"

    # Split build metadata into components
    IFS='.' read -ra parts1 <<< "$meta1"
    IFS='.' read -ra parts2 <<< "$meta2"

    local len1=${#parts1[@]}
    local len2=${#parts2[@]}
    local min_len=$(( len1 < len2 ? len1 : len2 ))

    # Compare component by component
    for ((i = 0; i < min_len; i++)); do
        if mulle-semver alphanumeric-compare --quiet "${parts1[i]}" "${parts2[i]}" >/dev/null 2>&1; then
            continue
        elif [ $? -eq 60 ]; then
            echo "first"
            return 60
        else
            echo "second"
            return 62
        fi
    done

    # If all compared parts are equal, longer one wins
    if [ $len1 -lt $len2 ]; then
        echo "first"
        return 60
    elif [ $len1 -gt $len2 ]; then
        echo "second"
        return 62
    else
        echo "equal"
        return 0
    fi
}

# Compare build metadata
compare_build_metadata "build.123.sha.abc123" "build.123.sha.def456"
```

## Error Handling

### Invalid Input

```bash
# Empty strings are valid (treated as empty)
mulle-semver alphanumeric-compare "" "alpha"
# Output: ASCENDING (empty string comes first)

# Control characters
mulle-semver alphanumeric-compare $'\x01' "a"
# Output: ASCENDING (control character comes first)

# Unicode characters (compared as-is in C locale)
mulle-semver alphanumeric-compare "café" "cafe"
# Output depends on byte values in C locale
```

### Edge Cases

```bash
# Very long strings
mulle-semver alphanumeric-compare "$(printf 'a%.0s' {1..10000})" "b"
# Output: ASCENDING (long string of 'a's < "b")

# Strings with embedded nulls
mulle-semver alphanumeric-compare "test"$'\x00'"string" "test"
# Behavior depends on shell handling of null bytes

# Identical strings of different lengths
mulle-semver alphanumeric-compare "test" "test"
# Output: SAME
```

## Use Cases

### Semantic Version Prerelease Comparison

Used internally by the `compare` command for comparing prerelease identifier parts:

```bash
# Prerelease identifier comparison
mulle-semver alphanumeric-compare "alpha" "beta"     # alpha < beta
mulle-semver alphanumeric-compare "beta" "rc"        # beta < rc
mulle-semver alphanumeric-compare "rc" "stable"      # rc < stable
```

### Build Metadata Sorting

Used for comparing build metadata components:

```bash
# Build metadata comparison
mulle-semver alphanumeric-compare "build" "test"     # build < test
mulle-semver alphanumeric-compare "sha" "tag"        # sha < tag
```

### Custom Identifier Sorting

Suitable for sorting custom identifiers in semantic versioning schemes:

```bash
# Custom identifier sorting
mulle-semver alphanumeric-compare "dev" "staging"    # dev < staging
mulle-semver alphanumeric-compare "prod" "dev"      # prod > dev
```

## See Also

- **[`compare`](compare.md)** - Compare full semantic versions
- **[`numeric-compare`](numeric-compare.md)** - Compare numeric parts only
- **[`parse`](parse.md)** - Parse semantic version strings