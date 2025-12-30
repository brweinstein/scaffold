#!/usr/bin/env bash

# Scaffold - Generate directory structures from text-based tree representations
# Bash implementation with same functionality as the Rust version

set -e

VERBOSE=false

usage() {
    echo "Usage: scaffold [-v] <input_file> [output_directory]"
    echo "   or: scaffold [-v] - [output_directory]  (read from stdin)"
    echo ""
    echo "Options:"
    echo "  -v, --verbose    Show each file/directory as it's created"
    exit 1
}

# Parse arguments
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

# Check for required arguments
if [ ${#POSITIONAL_ARGS[@]} -eq 0 ]; then
    usage
fi

INPUT_SOURCE="${POSITIONAL_ARGS[0]}"
OUTPUT_DIR="${POSITIONAL_ARGS[1]:-$(pwd)}"

# Read input lines
if [ "$INPUT_SOURCE" = "-" ]; then
    mapfile -t LINES
else
    if [ ! -f "$INPUT_SOURCE" ]; then
        echo "Error: Input file '$INPUT_SOURCE' not found" >&2
        exit 1
    fi
    mapfile -t LINES < "$INPUT_SOURCE"
fi

# Parse a line to extract depth, name, and whether it's a directory
parse_line() {
    local line="$1"
    
    # Skip empty lines or lines with only │
    if [[ -z "${line// /}" ]] || [[ "$line" =~ ^[[:space:]]*│[[:space:]]*$ ]]; then
        echo ""
        return
    fi
    
    # Remove comments (everything after #)
    line="${line%%#*}"
    
    # Check if line has tree characters
    if [[ "$line" =~ [│├└] ]]; then
        parse_tree_based "$line"
    else
        parse_tab_based "$line"
    fi
}

# Parse tab/space-based indentation
parse_tab_based() {
    local line="$1"
    local depth=0
    local remaining="$line"
    
    # Count depth by tabs or 4-space groups
    while true; do
        if [[ "$remaining" =~ ^$'\t'(.*)$ ]]; then
            ((depth++))
            remaining="${BASH_REMATCH[1]}"
        elif [[ "$remaining" =~ ^"    "(.*)$ ]]; then
            ((depth++))
            remaining="${BASH_REMATCH[1]}"
        elif [[ "$remaining" =~ ^" "(.*)$ ]]; then
            remaining="${BASH_REMATCH[1]}"
        else
            break
        fi
    done
    
    # Extract name
    local name="${remaining#"${remaining%%[![:space:]]*}"}"  # ltrim
    name="${name%"${name##*[![:space:]]}"}"                   # rtrim
    
    if [[ -z "$name" ]]; then
        echo ""
        return
    fi
    
    # Check if it's a directory (ends with /)
    local is_dir=false
    if [[ "$name" =~ /$ ]]; then
        is_dir=true
        name="${name%/}"
    fi
    
    echo "$depth|$name|$is_dir"
}

# Parse tree-character based format
parse_tree_based() {
    local line="$1"
    local depth=0
    local i=0
    local char
    local has_branch=false
    local remaining="$line"
    
    # Process tree characters
    while [ ${#remaining} -gt 0 ]; do
        char="${remaining:0:1}"
        
        if [ "$char" = "│" ]; then
            ((depth++))
            remaining="${remaining:1}"
            # Skip spaces after │
            while [[ "${remaining:0:1}" = " " ]]; do
                remaining="${remaining:1}"
            done
        elif [ "$char" = " " ]; then
            remaining="${remaining:1}"
        elif [ "$char" = "├" ] || [ "$char" = "└" ]; then
            has_branch=true
            remaining="${remaining:1}"
            # Skip ─ and spaces after branch
            while [[ "${remaining:0:1}" =~ [─[:space:]] ]]; do
                remaining="${remaining:1}"
            done
            break
        else
            break
        fi
    done
    
    if [ "$has_branch" = true ]; then
        ((depth++))
    fi
    
    # Extract name
    local name="${remaining#"${remaining%%[![:space:]]*}"}"
    name="${name%"${name##*[![:space:]]}"}"
    
    if [[ -z "$name" ]]; then
        echo ""
        return
    fi
    
    # Check if it's a directory
    local is_dir=false
    if [[ "$name" =~ /$ ]]; then
        is_dir=true
        name="${name%/}"
    fi
    
    echo "$depth|$name|$is_dir"
}

# Create the scaffold structure
create_scaffold() {
    local -a path_stack=("$OUTPUT_DIR")
    
    for line in "${LINES[@]}"; do
        local entry
        entry=$(parse_line "$line")
        
        if [[ -z "$entry" ]]; then
            continue
        fi
        
        IFS='|' read -r depth name is_dir <<< "$entry"
        
        # Adjust path stack to correct depth
        local target_len=$((depth + 1))
        while [ ${#path_stack[@]} -gt $target_len ]; do
            unset 'path_stack[-1]'
        done
        
        # Build current path
        local current_path="${path_stack[-1]}/$name"
        
        if [ "$is_dir" = "true" ]; then
            mkdir -p "$current_path"
            if [ "$VERBOSE" = true ]; then
                echo "  Created dir:  $current_path"
            fi
            path_stack+=("$current_path")
        else
            # Create parent directory if needed
            local parent_dir
            parent_dir=$(dirname "$current_path")
            mkdir -p "$parent_dir"
            
            # Create file
            touch "$current_path"
            if [ "$VERBOSE" = true ]; then
                echo "  Created file: $current_path"
            fi
        fi
    done
}

# Run the scaffold creation
create_scaffold

echo "Scaffold created successfully in: $OUTPUT_DIR"
