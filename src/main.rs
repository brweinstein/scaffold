use std::env;
use std::fs;
use std::io::{self, BufRead, BufReader};
use std::path::{Path, PathBuf};

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    
    let mut verbose = false;
    let mut positional_args = Vec::new();
    
    for arg in args.iter().skip(1) {
        if arg == "-v" || arg == "--verbose" {
            verbose = true;
        } else {
            positional_args.push(arg.as_str());
        }
    }
    
    if positional_args.is_empty() {
        eprintln!("Usage: scaffold [-v] <input_file> [output_directory]");
        eprintln!("   or: scaffold [-v] - [output_directory]  (read from stdin)");
        eprintln!("\nOptions:");
        eprintln!("  -v, --verbose    Show each file/directory as it's created");
        std::process::exit(1);
    }
    
    let input_source = positional_args[0];
    let output_dir = if positional_args.len() > 1 {
        PathBuf::from(positional_args[1])
    } else {
        env::current_dir()?
    };
    
    let lines = if input_source == "-" {
        let stdin = io::stdin();
        let reader = BufReader::new(stdin.lock());
        reader.lines().collect::<Result<Vec<_>, _>>()?
    } else {
        let file = fs::File::open(input_source)?;
        let reader = BufReader::new(file);
        reader.lines().collect::<Result<Vec<_>, _>>()?
    };
    
    create_scaffold(&lines, &output_dir, verbose)?;
    
    println!("Scaffold created successfully in: {}", output_dir.display());
    Ok(())
}

struct Entry {
    name: String,
    is_dir: bool,
    depth: usize,
}

fn parse_tree_line(line: &str) -> Option<Entry> {
    if line.trim().is_empty() || line.trim() == "│" {
        return None;
    }
    
    let content = if let Some(pos) = line.find('#') {
        &line[..pos]
    } else {
        line
    };
    
    let chars: Vec<char> = content.chars().collect();
    
    let has_tree_chars = chars.iter().any(|&c| c == '│' || c == '├' || c == '└');
    
    let (depth, name) = if !has_tree_chars {
        parse_tab_based(&chars)
    } else {
        parse_tree_based(&chars)
    };
    
    if name.is_empty() {
        return None;
    }
    
    let is_dir = name.ends_with('/');
    let name = if is_dir {
        name.trim_end_matches('/').to_string()
    } else {
        name
    };
    
    Some(Entry { name, is_dir, depth })
}

fn parse_tab_based(chars: &[char]) -> (usize, String) {
    let mut i = 0;
    let mut depth = 0;
    
    while i < chars.len() {
        if chars[i] == '\t' {
            depth += 1;
            i += 1;
        } else if i + 3 < chars.len() && chars[i..i+4].iter().all(|&c| c == ' ') {
            depth += 1;
            i += 4;
        } else if chars[i] == ' ' {
            i += 1;
        } else {
            break;
        }
    }
    
    let name: String = chars[i..].iter().collect();
    let name = name.trim().to_string();
    
    (depth, name)
}

fn parse_tree_based(chars: &[char]) -> (usize, String) {
    let mut depth = 0;
    let mut i = 0;
    let mut has_branch = false;
    
    while i < chars.len() {
        if chars[i] == '│' {
            depth += 1;
            i += 1;
            while i < chars.len() && chars[i] == ' ' {
                i += 1;
            }
        } else if chars[i] == ' ' {
            i += 1;
        } else if chars[i] == '├' || chars[i] == '└' {
            has_branch = true;
            i += 1;
            while i < chars.len() && (chars[i] == '─' || chars[i] == ' ') {
                i += 1;
            }
            break;
        } else {
            break;
        }
    }
    
    if has_branch {
        depth += 1;
    }
    
    let name: String = chars[i..].iter().collect();
    let name = name.trim().to_string();
    
    (depth, name)
}

fn create_scaffold(lines: &[String], base_dir: &Path, verbose: bool) -> io::Result<()> {
    let mut path_stack: Vec<PathBuf> = vec![base_dir.to_path_buf()];
    
    for line in lines {
        if let Some(entry) = parse_tree_line(line) {
            let target_len = entry.depth + 1;
            while path_stack.len() > target_len {
                path_stack.pop();
            }
            
            let current_path = path_stack.last().unwrap().join(&entry.name);
            
            if entry.is_dir {
                fs::create_dir_all(&current_path)?;
                if verbose {
                    println!("  Created dir:  {}", current_path.display());
                }
                path_stack.push(current_path);
            } else {
                if let Some(parent) = current_path.parent() {
                    fs::create_dir_all(parent)?;
                }
                fs::File::create(&current_path)?;
                if verbose {
                    println!("  Created file: {}", current_path.display());
                }
            }
        }
    }
    
    Ok(())
}
