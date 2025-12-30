# Scaffold

A lightweight Rust utility to generate directory structures from text-based tree representations.

## Features

- Parse and create file/directory structures from tree diagrams
- Supports **tree-character** format (├──, └──, │)
- Supports **tab/space-based** indentation
- Read from file or stdin
- Handles nested structures of any depth

## Installation

```bash
cargo install --path .
```

This installs `scaffold` to your Cargo bin directory, making it available globally.

## Usage

```bash
scaffold <input_file> [output_directory]
scaffold - [output_directory]  # read from stdin
```

If no output directory is specified, uses the current directory.

## Examples

### Tree-Character Format

```
project/
├── src/
│   ├── main.rs
│   ├── lib.rs
│   └── utils/
│       └── helper.rs
├── tests/
│   └── test.rs
└── README.md
```

### Tab/Space-Based Format

```
project/
    src/
        main.rs
        lib.rs
        utils/
            helper.rs
    tests/
        test.rs
    README.md
```

Both formats produce the same structure:

```bash
scaffold tree.md ./output
```

```
output/
└── project/
    ├── src/
    │   ├── main.rs
    │   ├── lib.rs
    │   └── utils/
    │       └── helper.rs
    ├── tests/
    │   └── test.rs
    └── README.md
```

## Format Rules

- **Directories**: End with `/`
- **Files**: No trailing `/`
- **Comments**: Everything after `#` is ignored
- **Indentation**: 1 tab or 4 spaces = 1 level

## Example Usage

```bash
# From file
scaffold pytree.md ./my-project

# From stdin
cat structure.txt | scaffold - ./output

# Use current directory
scaffold tree.md

# Verbose output
scaffold -v pytree.md ./my-project
```
Note for stdin: ENTER creates a new line character, to stop passing input you must put EOF (end of file) which is CTRL-D on linux.
