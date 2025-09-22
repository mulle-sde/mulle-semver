# version

Show version information for mulle-semver.

## Synopsis

```bash
mulle-semver version
```

## Description

The `version` command displays the version number of the mulle-semver tool. This is useful for:
- Checking which version of mulle-semver is installed
- Troubleshooting version-related issues
- Verifying installation integrity
- Script compatibility checks

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |

## Examples

### Basic Usage
```bash
# Display the version number
mulle-semver version
```

### Script Integration
```bash
#!/bin/bash
# Check mulle-semver version in scripts
MULLE_SEMVER_VERSION=$(mulle-semver version)
echo "Using mulle-semver version: $MULLE_SEMVER_VERSION"

# Version comparison in scripts
if [[ "$(mulle-semver version)" == "1.0.6" ]]; then
    echo "Running expected version"
else
    echo "Warning: Unexpected mulle-semver version"
fi
```

### Debugging
```bash
# Verify installation
if mulle-semver version >/dev/null 2>&1; then
    echo "mulle-semver is properly installed: $(mulle-semver version)"
else
    echo "mulle-semver installation issue"
fi
```

## Output Format

The command outputs a single line containing the version number:
```
1.0.6
```

## How It Works

The version command simply prints the value of the `MULLE_EXECUTABLE_VERSION` variable, which is hardcoded in the mulle-semver script.

## Use Cases

### Installation Verification
```bash
# Confirm successful installation
mulle-semver version

# Check version in CI/CD pipelines
if [ "$(mulle-semver version)" != "1.0.6" ]; then
    echo "Version mismatch detected"
    exit 1
fi
```

### Compatibility Checks
```bash
# Ensure minimum version requirements
CURRENT_VERSION=$(mulle-semver version)
REQUIRED_VERSION="1.0.0"

if ! mulle-semver compare "$CURRENT_VERSION" "$REQUIRED_VERSION" >/dev/null 2>&1; then
    echo "mulle-semver version $CURRENT_VERSION is too old"
    exit 1
fi
```

### Build System Integration
```bash
# Use in Makefiles
MULLE_SEMVER_VERSION:=$(shell mulle-semver version)

# Conditional compilation based on version
ifeq ($(MULLE_SEMVER_VERSION),1.0.6)
    CFLAGS += -DMULLE_SEMVER_LATEST
endif
```

## Troubleshooting

### No Output
- Ensure mulle-semver is properly installed
- Check that the executable is in your PATH
- Verify file permissions on the mulle-semver script

### Permission Issues
- Check execute permissions: `ls -la $(which mulle-semver)`
- Ensure the script is readable and executable

### Path Issues
- Verify mulle-semver is in PATH: `which mulle-semver`
- Check for multiple installations
- Ensure the correct version is being executed

## Version Information

- **Current Version**: 1.0.6
- **Release Date**: Part of mulle-semver 1.0.6 release
- **Compatibility**: Compatible with Semantic Versioning 2.0.0 specification

## See Also

- [`libexec-dir`](libexec-dir.md) - Print path to mulle-semver libexec
- [`parse`](parse.md) - Parse semantic version strings
- [`compare`](compare.md) - Compare semantic version strings