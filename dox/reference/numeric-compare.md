# mulle-semver numeric-compare

## Overview

The `numeric-compare` command compares two numeric strings according to semantic versioning rules. It handles arbitrarily large numbers by comparing them in chunks, making it suitable for version numbers that exceed standard integer limits. The command supports wildcard matching and provides both human-readable output and machine-readable exit codes.

## Usage

```bash
mulle-semver numeric-compare [options] <number1> <number2>
```

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |
| `-q`, `--quiet` | Suppress output, only return exit code |

## Exit Codes

| Exit Code | Result | Description |
|-----------|--------|-------------|
| 0 | SAME | Numbers are identical |
| 60 | ASCENDING | First number is less than second number |
| 62 | DESCENDING | First number is greater than second number |

## Examples

### Basic Numeric Comparison

```bash
# Compare small numbers
mulle-semver numeric-compare "123" "456"
# Output: ASCENDING
# Exit code: 60

mulle-semver numeric-compare "100" "50"
# Output: DESCENDING
# Exit code: 62

mulle-semver numeric-compare "42" "42"
# Output: SAME
# Exit code: 0
```

### Large Number Comparison

```bash
# Compare very large numbers (beyond standard integer limits)
mulle-semver numeric-compare "999999999999999999999" "1000000000000000000000"
# Output: ASCENDING

mulle-semver numeric-compare "18446744073709551616" "18446744073709551615"
# Output: DESCENDING
```

### Wildcard Support

```bash
# Wildcards match any value
mulle-semver numeric-compare "123" "*"
# Output: SAME
# Exit code: 0

mulle-semver numeric-compare "*" "456"
# Output: SAME
# Exit code: 0

mulle-semver numeric-compare "*" "*"
# Output: SAME
# Exit code: 0
```

### Quiet Mode

```bash
# Use exit codes for scripting
if mulle-semver numeric-compare --quiet "100" "200"; then
    echo "Numbers are equal"
elif [ $? -eq 60 ]; then
    echo "First number is smaller"
elif [ $? -eq 62 ]; then
    echo "First number is larger"
fi
```

## Comparison Rules

### Numeric Comparison Logic

1. **Exact Match**: Identical strings return SAME
2. **Wildcard Handling**: Either number being "*" returns SAME
3. **Length Comparison**: Shorter numbers are smaller (except when padded)
4. **Chunk-wise Comparison**: Large numbers compared in 4-digit chunks
5. **Leading Zero Handling**: Numbers with different lengths are compared by actual numeric value

### Special Cases

```bash
# Different lengths
mulle-semver numeric-compare "100" "99"
# Output: DESCENDING (100 > 99)

mulle-semver numeric-compare "99" "100"
# Output: ASCENDING (99 < 100)

# Same numeric value, different representations
mulle-semver numeric-compare "00100" "100"
# Output: SAME (both represent 100)

# Very large numbers
mulle-semver numeric-compare "1000000000000000000000" "999999999999999999999"
# Output: DESCENDING
```

## Implementation Details

### Chunk-wise Processing

For numbers larger than 4 digits, the comparison is performed in chunks:

```bash
# Number: 12345678901234567890
# Chunks: 1234 5678 9012 3456 7890
```

This allows comparison of arbitrarily large numbers without integer overflow.

### Performance Characteristics

- **Small numbers** (≤ 4 digits): Direct integer comparison
- **Large numbers** (> 4 digits): Chunk-wise string comparison
- **Wildcards**: Constant time (always SAME)
- **Memory usage**: O(n) where n is the length of the longer number

## Integration Examples

### Shell Scripting

```bash
#!/bin/bash

numeric_compare() {
    local n1="$1"
    local n2="$2"

    if mulle-semver numeric-compare --quiet "$n1" "$n2" >/dev/null 2>&1; then
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
result=$(numeric_compare "100" "200")
echo "100 is $result than 200"
```

### Version Component Comparison

```bash
#!/bin/bash

compare_version_parts() {
    local part1="$1"
    local part2="$2"

    # Extract numeric parts from version components
    local num1=$(echo "$part1" | sed 's/[^0-9]*\([0-9]*\).*/\1/')
    local num2=$(echo "$part2" | sed 's/[^0-9]*\([0-9]*\).*/\1/')

    if [ -z "$num1" ] && [ -z "$num2" ]; then
        echo "both empty"
        return 0
    fi

    numeric_compare "$num1" "$num2"
}

# Compare version components
compare_version_parts "beta.10" "beta.2"  # 10 > 2
compare_version_parts "rc.1" "rc.10"      # 1 < 10
```

### Build Number Validation

```bash
#!/bin/bash

validate_build_number() {
    local build_num="$1"
    local min_build="$2"

    # Check if build number is valid
    if ! mulle-semver numeric-compare --quiet "$build_num" "$build_num" >/dev/null 2>&1; then
        echo "Invalid build number: $build_num"
        return 1
    fi

    # Check minimum build requirement
    if mulle-semver numeric-compare --quiet "$build_num" "$min_build" >/dev/null 2>&1; then
        echo "Build number meets minimum requirement"
        return 0
    elif [ $? -eq 60 ]; then
        echo "Build number too low: $build_num < $min_build"
        return 1
    else
        echo "Build number acceptable: $build_num >= $min_build"
        return 0
    fi
}

validate_build_number "12345" "10000"
```

### Large Number Processing

```bash
#!/bin/bash

# Process large build numbers from CI systems
LARGE_BUILD="18446744073709551616"

if mulle-semver numeric-compare --quiet "$LARGE_BUILD" "10000000000000000000"; then
    echo "Build number is at least 10^19"
else
    echo "Build number is less than 10^19"
fi
```

## Error Handling

### Invalid Input

```bash
# Non-numeric characters
mulle-semver numeric-compare "123abc" "456"
# Error: "123abc" is not a valid semver numeric identifier

# Empty strings
mulle-semver numeric-compare "" "123"
# Error: Empty numeric identifier

# Leading zeros (except for zero itself)
mulle-semver numeric-compare "0123" "123"
# This is actually valid - both represent 123
```

### Edge Cases

```bash
# Zero handling
mulle-semver numeric-compare "0" "00"
# Output: SAME (both represent zero)

mulle-semver numeric-compare "0" "1"
# Output: ASCENDING

# Very long numbers
mulle-semver numeric-compare "1$(printf '0%.0s' {1..1000})" "2"
# Output: ASCENDING (very long number ending in many zeros vs 2)
```

## Use Cases

### Semantic Version Components

Used internally by the `compare` command for comparing major, minor, and patch version numbers:

```bash
# Major version comparison
mulle-semver numeric-compare "2" "1"  # 2 > 1

# Minor version comparison
mulle-semver numeric-compare "10" "9"  # 10 > 9

# Patch version comparison
mulle-semver numeric-compare "5" "12"  # 5 < 12
```

### Prerelease Identifiers

Used for comparing numeric parts of prerelease identifiers:

```bash
# Compare prerelease numbers
mulle-semver numeric-compare "1" "2"      # 1 < 2 (beta.1 < beta.2)
mulle-semver numeric-compare "10" "2"     # 10 > 2 (rc.10 > rc.2)
```

### Build Numbers

Suitable for comparing large build numbers from CI/CD systems:

```bash
# Jenkins build numbers
mulle-semver numeric-compare "1847" "1846"

# GitHub Actions run numbers
mulle-semver numeric-compare "123456789" "123456788"
```

## See Also

- **[`compare`](compare.md)** - Compare full semantic versions
- **[`alphanumeric-compare`](alphanumeric-compare.md)** - Compare alphanumeric parts
- **[`parse`](parse.md)** - Parse semantic version strings