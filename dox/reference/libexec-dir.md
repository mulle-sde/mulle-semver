# libexec-dir

Print the path to mulle-semver's libexec directory.

## Synopsis

```bash
mulle-semver libexec-dir
```

## Description

The `libexec-dir` command displays the absolute path to mulle-semver's libexec directory. This directory contains internal scripts and supporting files used by mulle-semver for parsing and comparing semantic versions.

This command is primarily useful for:
- Debugging and troubleshooting
- Integration with other tools
- Understanding mulle-semver's installation structure
- Script development that needs to reference mulle-semver internals

## Options

| Option | Description |
|--------|-------------|
| `-h`, `--help` | Show help information |

## Examples

### Basic Usage
```bash
# Display the libexec directory path
mulle-semver libexec-dir
```

### Script Integration
```bash
#!/bin/bash
# Get the libexec directory for script development
LIBEXEC_DIR=$(mulle-semver libexec-dir)
echo "Mulle-semver libexec directory: $LIBEXEC_DIR"

# List contents of libexec directory
ls -la "$LIBEXEC_DIR"
```

### Debugging
```bash
# Check if libexec directory exists and is accessible
if [ -d "$(mulle-semver libexec-dir)" ]; then
    echo "Libexec directory is accessible"
else
    echo "Libexec directory is not accessible"
fi
```

## Output Format

The command outputs a single line containing the absolute path:
```
/usr/local/libexec/mulle-semver
```

## How It Works

The libexec-dir command simply prints the value of the `MULLE_SEMVER_LIBEXEC_DIR` environment variable, which is set during mulle-semver's initialization.

## Use Cases

### Development and Debugging
```bash
# Examine internal scripts
find "$(mulle-semver libexec-dir)" -name "*.sh" | head -5

# Check for specific internal files
ls "$(mulle-semver libexec-dir)/mulle-semver-"*
```

### Integration Scripts
```bash
# Source internal functions (if appropriate)
LIBEXEC_DIR=$(mulle-semver libexec-dir)
# Note: Only source files that are documented as safe to use
```

### Build System Integration
```bash
# Use in Makefiles or build scripts
MULLE_SEMVER_LIBEXEC:=$(shell mulle-semver libexec-dir)
```

## Troubleshooting

### Empty Output
- Ensure mulle-semver is properly installed
- Check that the installation is complete
- Verify environment variables are set correctly

### Permission Issues
- Check read permissions on the libexec directory
- Ensure mulle-semver has proper access to its installation directory

### Path Issues
- Verify that the path exists: `ls -la "$(mulle-semver libexec-dir)"`
- Check for symbolic links or mount points
- Ensure the installation wasn't corrupted

## Security Considerations

- The libexec directory contains internal implementation files
- These files are not part of the public API
- Direct use of internal files may break with future versions
- Always prefer documented command-line interfaces over direct file access

## See Also

- [`version`](version.md) - Show version information
- [`parse`](parse.md) - Parse semantic version strings
- [`compare`](compare.md) - Compare semantic version strings