# mulle-semver sort

## Overview

The `sort` command sorts semantic versions according to semantic versioning rules. It supports multiple sorting algorithms (quicksort, mergesort, unixsort) and handles the complex rules for prerelease versions correctly. This command is essential for organizing version lists and ensuring proper version ordering in package management and dependency resolution.

## Usage

```bash
mulle-semver sort [options] <version>*
```

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |
| `-q`, `--quiet` | Suppress informational output |
| `-l`, `--lenient` | Ignore invalid semver versions instead of failing |
| `-r`, `--reverse` | Output in descending order |
| `-p`, `--pretty` | Pretty-print output with version components |
| `--mergesort` | Use mergesort algorithm (slower but stable) |
| `--quicksort` | Use quicksort algorithm (default, faster) |
| `--unixsort` | Use system sort (fastest but incorrect for prereleases) |

## Examples

### Basic Sorting

```bash
# Sort versions in ascending order
mulle-semver sort 1.2.3 1.0.0 1.1.0 2.0.0
# Output: 1.0.0 1.1.0 1.2.3 2.0.0

# Sort with prereleases
mulle-semver sort 1.0.0-beta 1.0.0-alpha 1.0.0 1.0.0-rc
# Output: 1.0.0-alpha 1.0.0-beta 1.0.0-rc 1.0.0
```

### Reverse Sorting

```bash
# Sort in descending order
mulle-semver sort --reverse 1.0.0 1.1.0 1.2.0
# Output: 2.0.0 1.2.0 1.1.0 1.0.0
```

### Reading from Standard Input

```bash
# Read versions from stdin (use '-' as argument)
echo -e "1.2.0\n1.0.0\n1.1.0" | mulle-semver sort -
# Output: 1.0.0 1.1.0 1.2.0
```

### Pretty Output

```bash
# Show detailed version components
mulle-semver sort --pretty 1.0.0-beta.1 1.0.0-alpha.2
# Output:
# 1.0.0-alpha.2 (major=1, minor=0, patch=0, prerelease=alpha.2, build=)
# 1.0.0-beta.1 (major=1, minor=0, patch=0, prerelease=beta.1, build=)
```

### Lenient Mode

```bash
# Ignore invalid versions
mulle-semver sort --lenient 1.0.0 invalid-version 1.1.0
# Output: 1.0.0 1.1.0
# (invalid-version is silently ignored)
```

### Algorithm Comparison

```bash
# Compare sorting algorithms
VERSIONS="1.0.0-beta 1.0.0-alpha 1.0.0-rc 1.0.0"

# Quicksort (default)
mulle-semver sort --quicksort $VERSIONS
# Output: 1.0.0-alpha 1.0.0-beta 1.0.0-rc 1.0.0

# Mergesort
mulle-semver sort --mergesort $VERSIONS
# Output: 1.0.0-alpha 1.0.0-beta 1.0.0-rc 1.0.0

# Unix sort (incorrect for prereleases)
mulle-semver sort --unixsort $VERSIONS
# Output: 1.0.0 1.0.0-alpha 1.0.0-beta 1.0.0-rc
```

## Sorting Rules

### Semantic Version Ordering

Versions are sorted according to the semantic versioning specification:

1. **Major version** (highest precedence)
2. **Minor version**
3. **Patch version**
4. **Prerelease identifiers** (lexicographically, with numeric parts compared numerically)
5. **Build metadata** (not used for sorting precedence)

### Prerelease Handling

Prerelease versions are sorted before their normal release counterparts:

```bash
# Prerelease sorting
mulle-semver sort 1.0.0 1.0.0-rc 1.0.0-beta 1.0.0-alpha
# Output: 1.0.0-alpha 1.0.0-beta 1.0.0-rc 1.0.0
```

### Complex Prerelease Identifiers

```bash
# Numeric vs alphabetic identifiers
mulle-semver sort 1.0.0-2 1.0.0-10 1.0.0-rc 1.0.0-beta
# Output: 1.0.0-2 1.0.0-10 1.0.0-beta 1.0.0-rc

# Mixed alphanumeric
mulle-semver sort 1.0.0-alpha.1 1.0.0-alpha.2 1.0.0-beta.1
# Output: 1.0.0-alpha.1 1.0.0-alpha.2 1.0.0-beta.1
```

## Algorithm Details

### Quicksort (Default)

- **Algorithm**: In-place quicksort with custom pivot selection
- **Performance**: O(n log n) average case, O(n²) worst case
- **Stability**: Not stable (equal elements may change order)
- **Memory**: O(log n) additional space
- **Best for**: General use, good performance on random data

### Mergesort

- **Algorithm**: Bottom-up mergesort with temporary arrays
- **Performance**: O(n log n) worst case
- **Stability**: Stable (equal elements maintain relative order)
- **Memory**: O(n) additional space
- **Best for**: When stability is important, predictable performance

### Unix Sort

- **Algorithm**: System `sort` command with custom field separators
- **Performance**: O(n log n) using system sort
- **Stability**: Depends on system sort implementation
- **Memory**: Minimal additional memory
- **Limitations**: Incorrect handling of prerelease versions
- **Best for**: Large datasets where prerelease correctness is not critical

## Integration Examples

### Shell Scripting

```bash
#!/bin/bash

sort_versions() {
    # Sort versions from arguments or stdin
    if [ $# -eq 0 ]; then
        mulle-semver sort -
    else
        mulle-semver sort "$@"
    fi
}

# Usage
sort_versions 2.0.0 1.5.0 1.10.0  # Arguments
echo -e "2.0.0\n1.5.0\n1.10.0" | sort_versions  # Stdin
```

### Package Version Management

```bash
#!/bin/bash

get_latest_version() {
    local package="$1"
    local versions_file="$2"

    # Extract versions for package and sort them
    grep "^$package:" "$versions_file" | \
        cut -d: -f2 | \
        mulle-semver sort | \
        tail -1
}

# Usage
LATEST=$(get_latest_version "my-package" "available_versions.txt")
echo "Latest version of my-package: $LATEST"
```

### Dependency Resolution

```bash
#!/bin/bash

resolve_dependencies() {
    local requirements_file="$1"

    while IFS=':' read -r package constraint; do
        # Find all available versions
        local available_versions
        available_versions=$(get_available_versions "$package")

        # Find versions that satisfy the constraint
        local satisfying_versions=""
        for version in $available_versions; do
            if mulle-semver qualify --quiet "$constraint" "$version"; then
                satisfying_versions="$satisfying_versions $version"
            fi
        done

        # Pick the highest satisfying version
        local best_version
        best_version=$(echo "$satisfying_versions" | mulle-semver sort | tail -1)

        echo "$package: $best_version"
    done < "$requirements_file"
}
```

### Version History Analysis

```bash
#!/bin/bash

analyze_version_history() {
    local changelog_file="$1"

    # Extract version numbers from changelog
    grep -E '^## \[[0-9]+\.[0-9]+\.[0-9]+' "$changelog_file" | \
        sed 's/.*\[\([0-9.]*\)\].*/\1/' | \
        mulle-semver sort --reverse | \
        head -10
}

# Show last 10 versions in descending order
analyze_version_history "CHANGELOG.md"
```

### CI/CD Pipeline Integration

```bash
#!/bin/bash

validate_version_order() {
    local versions_file="$1"

    # Read all versions
    local versions
    versions=$(cat "$versions_file")

    # Sort them
    local sorted_versions
    sorted_versions=$(echo "$versions" | mulle-semver sort)

    # Check if they were already sorted
    if [ "$versions" = "$sorted_versions" ]; then
        echo "✅ Versions are properly sorted"
        return 0
    else
        echo "❌ Versions are not properly sorted"
        echo "Expected order:"
        echo "$sorted_versions"
        return 1
    fi
}

# Usage in CI pipeline
if ! validate_version_order "versions.txt"; then
    exit 1
fi
```

## Performance Considerations

### Algorithm Selection

```bash
# For small lists (< 100 items), any algorithm works
mulle-semver sort $SMALL_LIST

# For large lists with stability requirements
mulle-semver sort --mergesort $LARGE_LIST

# For maximum speed (when prerelease correctness not critical)
mulle-semver sort --unixsort $VERY_LARGE_LIST
```

### Memory Usage

```bash
# Quicksort uses minimal memory
mulle-semver sort --quicksort $VERSIONS

# Mergesort uses additional memory proportional to input size
mulle-semver sort --mergesort $VERSIONS
```

### Input Size Handling

```bash
# For very large inputs, consider preprocessing
large_sort() {
    local input_file="$1"

    # Pre-filter and validate versions
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+' "$input_file" | \
        mulle-semver sort --unixsort
}

large_sort "millions_of_versions.txt"
```

## Error Handling

### Invalid Versions

```bash
# Without lenient mode - fails on invalid input
mulle-semver sort 1.0.0 invalid 2.0.0
# Error: Invalid semver "invalid"

# With lenient mode - ignores invalid versions
mulle-semver sort --lenient 1.0.0 invalid 2.0.0
# Output: 1.0.0 2.0.0
```

### Empty Input

```bash
# Empty input
mulle-semver sort
# Error: At least one version required

# Empty stdin
echo "" | mulle-semver sort -
# Output: (no output)
```

### Duplicate Versions

```bash
# Duplicate versions are preserved in relative order
mulle-semver sort 1.0.0 2.0.0 1.0.0
# Output: 1.0.0 1.0.0 2.0.0
```

## Use Cases

### Package Registry Management

Used by package registries to maintain sorted version lists:

```bash
# Sort package versions for display
mulle-semver sort --reverse $ALL_PACKAGE_VERSIONS
```

### Dependency Lock Files

Ensures consistent dependency resolution across environments:

```bash
# Sort dependencies in lock file
mulle-semver sort $DEPENDENCY_VERSIONS > sorted_dependencies.txt
```

### Release Management

Organize release versions and prereleases:

```bash
# Sort releases with prereleases
mulle-semver sort $RELEASE_VERSIONS $PRERELEASE_VERSIONS
```

### Migration Planning

Identify version upgrade paths:

```bash
# Find versions between current and target
mulle-semver sort $CURRENT_VERSION $TARGET_VERSION $INTERMEDIATE_VERSIONS
```

## See Also

- **[`qualify`](qualify.md)** - Check if versions match qualifiers
- **[`compare`](compare.md)** - Compare two specific versions
- **[`search`](search.md)** - Search for versions matching qualifiers