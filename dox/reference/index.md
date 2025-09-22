# mulle-semver Command Reference

## Overview

**mulle-semver** is a command-line tool for parsing, comparing, and manipulating semantic version strings according to the semantic versioning specification. It provides comprehensive support for version parsing, comparison operations, qualifier matching, and version sorting with proper handling of prerelease versions.

## Command Categories

### Core Operations
- **[`parse`](parse.md)** - Parse semantic version strings and extract components
- **[`compare`](compare.md)** - Compare two semantic version strings
- **[`numeric-compare`](numeric-compare.md)** - Compare numeric version components
- **[`alphanumeric-compare`](alphanumeric-compare.md)** - Compare alphanumeric version components

### Qualifier Operations
- **[`qualify`](qualify.md)** - Check if versions match semver qualifiers
- **[`qualifier-type`](qualifier-type.md)** - Analyze qualifier type and scope
- **[`search`](search.md)** - Find highest version matching qualifiers

### Sorting Operations
- **[`sort`](sort.md)** - Sort versions according to semver rules

### Utility Commands
- **[`libexec-dir`](libexec-dir.md)** - Print path to mulle-semver libexec
- **[`version`](version.md)** - Show version information

## Quick Start Examples

### Basic Version Parsing

```bash
# Parse a semantic version
mulle-semver parse "1.2.3-beta.1+build.456"
# Output: 1.2.3-beta.1+build.456

# Parse multiple versions
mulle-semver parse "1.0.0" "2.1.0" "1.5.0-beta"
```

### Version Comparison

```bash
# Compare two versions
mulle-semver compare "1.2.3" "1.3.0"
# Output: ascending (1.2.3 < 1.3.0)

# Check if version satisfies constraint
mulle-semver qualify ">=1.0.0 <2.0.0" "1.5.0"
# Output: YES
```

### Version Sorting

```bash
# Sort versions in ascending order
mulle-semver sort 1.2.3 1.0.0 1.1.0 2.0.0
# Output: 1.0.0 1.1.0 1.2.3 2.0.0

# Sort with prereleases
mulle-semver sort 1.0.0 1.0.0-beta 1.0.0-alpha
# Output: 1.0.0-alpha 1.0.0-beta 1.0.0
```

### Advanced Qualifier Matching

```bash
# Complex range matching
mulle-semver qualify ">=1.0.0 <2.0.0 || >=3.0.0 <4.0.0" "3.5.0"
# Output: YES

# Tilde and caret operators
mulle-semver qualify "~1.2.3" "1.2.7"    # Patch-level compatible
mulle-semver qualify "^1.2.3" "1.5.0"    # Minor-level compatible
```

## Command Reference Table

| Command | Category | Description |
|---------|----------|-------------|
| `parse` | Core | Parse semantic version strings and extract components |
| `compare` | Core | Compare two semantic version strings |
| `numeric-compare` | Core | Compare numeric version components |
| `alphanumeric-compare` | Core | Compare alphanumeric version components |
| `qualify` | Qualifier | Check if versions match semver qualifiers |
| `qualifier-type` | Qualifier | Analyze qualifier type and scope |
| `search` | Qualifier | Find highest version matching qualifiers |
| `sort` | Sorting | Sort versions according to semver rules |
| `libexec-dir` | Utility | Print path to mulle-semver libexec |
| `version` | Utility | Show version information |

## Getting Help

### Command Help

```bash
# Get help for a specific command
mulle-semver <command> --help

# List all available commands
mulle-semver --help

# Get detailed command information
mulle-semver <command> --help --verbose
```

### Documentation

- Each command has a dedicated documentation file in this reference
- Use `--help` for quick command usage
- Check examples in each command's documentation

## Common Workflows

### Package Version Management

1. **Validate version format**: `mulle-semver parse "1.2.3"`
2. **Check compatibility**: `mulle-semver qualify "^1.0.0" "1.5.0"`
3. **Find latest compatible**: `mulle-semver search ">=1.0.0 <2.0.0" 1.1.0 1.2.0 1.5.0`
4. **Sort release versions**: `mulle-semver sort --reverse 1.0.0 1.1.0 1.2.0`

### Dependency Resolution

1. **Parse dependency requirements**: Extract version constraints
2. **Validate constraint syntax**: `mulle-semver qualifier-type ">=1.0.0"`
3. **Find matching versions**: `mulle-semver search ">=1.0.0 <2.0.0" available_versions.txt`
4. **Resolve conflicts**: Compare multiple constraint sets

### Release Management

1. **Validate release version**: `mulle-semver parse "1.2.3"`
2. **Check prerelease ordering**: `mulle-semver sort 1.2.3-rc.1 1.2.3-rc.2 1.2.3`
3. **Verify compatibility**: `mulle-semver qualify ">=1.0.0" "1.2.3"`
4. **Generate changelog**: Sort versions for release notes

## Semantic Versioning Rules

mulle-semver follows the semantic versioning specification:

### Version Format
```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)
- **PRERELEASE**: Pre-release identifiers (alpha, beta, rc)
- **BUILD**: Build metadata (ignored in comparisons)

### Comparison Rules

1. **Major, Minor, Patch**: Numeric comparison
2. **Prerelease**: Lexicographic comparison, prerelease < release
3. **Build metadata**: Ignored in version comparisons

### Prerelease Ordering

```bash
# Prerelease versions come before release versions
1.0.0-alpha < 1.0.0-beta < 1.0.0-rc < 1.0.0

# Numeric identifiers compare numerically
1.0.0-rc.1 < 1.0.0-rc.2 < 1.0.0-rc.10
```

## Troubleshooting

### Common Issues

```bash
# Invalid version format
mulle-semver parse "1.2"
# Error: Invalid semver format

# Malformed qualifier
mulle-semver qualify "invalid" "1.2.3"
# Error: Invalid qualifier syntax

# No matching versions
mulle-semver search ">=2.0.0" 1.0.0 1.5.0
# Returns exit code 2 (no match found)
```

### Version Format Problems

```bash
# Missing patch version
mulle-semver parse "1.2"        # Invalid
mulle-semver parse "1.2.0"      # Valid

# Invalid prerelease
mulle-semver parse "1.2.3-beta@invalid"  # Invalid
mulle-semver parse "1.2.3-beta.1"        # Valid
```

### Qualifier Issues

```bash
# Spaces in qualifiers (normalized)
mulle-semver qualify ">= 1.0.0" "1.5.0"  # Valid (spaces trimmed)

# Invalid operators
mulle-semver qualify "==1.2.3" "1.2.3"   # Invalid operator

# Malformed ranges
mulle-semver qualify "1.0.0 -" "1.5.0"   # Incomplete range
```

## Advanced Usage

### Scripting Integration

```bash
#!/bin/bash

# Function to find latest compatible version
find_latest_compatible() {
    local constraint="$1"
    shift
    local versions=("$@")

    # Search returns the highest matching version
    mulle-semver search "$constraint" "${versions[@]}"
}

# Usage
LATEST=$(find_latest_compatible ">=1.0.0 <2.0.0" "1.1.0" "1.5.0" "2.0.0")
echo "Latest compatible: $LATEST"
```

### CI/CD Integration

```bash
#!/bin/bash

# Validate version bump
validate_version_bump() {
    local current="$1"
    local new="$2"

    # Parse both versions
    if ! mulle-semver parse "$current" >/dev/null ||
       ! mulle-semver parse "$new" >/dev/null; then
        echo "Invalid version format"
        return 1
    fi

    # Compare versions
    case $(mulle-semver compare "$current" "$new") in
        "same")
            echo "Version unchanged"
            return 1
            ;;
        "ascending")
            echo "Version increased"
            ;;
        "descending")
            echo "Version decreased (downgrade)"
            ;;
    esac
}
```

### Package Registry Operations

```bash
#!/bin/bash

# Publish package with version validation
publish_package() {
    local name="$1"
    local version="$2"

    # Validate version format
    if ! mulle-semver parse "$version" >/dev/null; then
        echo "Invalid version: $version"
        return 1
    fi

    # Check if version already exists
    if package_exists "$name" "$version"; then
        echo "Version $version already exists"
        return 1
    fi

    # Publish package
    upload_package "$name" "$version"
}
```

## Performance Considerations

### Large Version Lists

```bash
# For large datasets, use efficient algorithms
mulle-semver sort --quicksort large_version_list.txt

# For memory-constrained environments
mulle-semver sort --unixsort massive_version_list.txt
```

### Batch Processing

```bash
# Process versions in batches
split -l 1000 versions.txt batch_
for batch in batch_*; do
    mulle-semver sort "$batch" >> sorted_versions.txt
done
```

## Related Documentation

- **[TODO.md](TODO.md)** - Current development status and process guide
- **[README.md](../../README.md)** - Project overview and installation
- **[mulle-sde.md](../mulle-sde.md)** - Build system guidelines
- **[mulle-test.md](../mulle-test.md)** - Testing guidelines

## Standards Compliance

mulle-semver implements the semantic versioning specification:

- **SemVer 2.0.0**: Full compliance with semantic versioning rules
- **Prerelease Handling**: Correct ordering of prerelease versions
- **Build Metadata**: Proper parsing and comparison rules
- **Qualifier Syntax**: Support for npm-style version ranges and operators

## Error Codes

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | Usage error / invalid arguments |
| 2 | No matching version found |
| 48 | Empty qualifier |
| 49 | Invalid qualifier |
| 50 | Valid semver version |
| 52 | Single match qualifier |
| 53 | Multi-match qualifier |