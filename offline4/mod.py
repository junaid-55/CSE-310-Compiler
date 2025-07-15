#!/usr/bin/env python3

import re
import sys

def remove_push_pop_pairs(asm_code):
    """
    Remove consecutive PUSH AX / POP AX pairs that do nothing
    """
    lines = asm_code.strip().split('\n')
    optimized_lines = []
    i = 0
    removed_pairs = 0
    
    while i < len(lines):
        current_line = lines[i].strip()
        
        # Check if current line is PUSH AX (with optional comment)
        if re.match(r'^\s*PUSH\s+AX\s*(;.*)?$', current_line, re.IGNORECASE):
            # Look ahead to see if next non-empty, non-comment line is POP AX
            j = i + 1
            found_pop = False
            intermediate_lines = []
            
            # Skip empty lines and comments between PUSH and POP
            while j < len(lines):
                next_line = lines[j].strip()
                
                # Skip empty lines
                if not next_line:
                    intermediate_lines.append(lines[j])
                    j += 1
                    continue
                    
                # Skip comment-only lines
                if next_line.startswith(';'):
                    intermediate_lines.append(lines[j])
                    j += 1
                    continue
                
                # Check if it's POP AX
                if re.match(r'^\s*POP\s+AX\s*(;.*)?$', next_line, re.IGNORECASE):
                    found_pop = True
                    break
                else:
                    # Found some other instruction, break
                    break
            
            if found_pop:
                # Skip both PUSH AX and POP AX
                print(f"Removing PUSH/POP pair: lines {i+1}-{j+1}")
                # Keep any intermediate comment-only or empty lines
                optimized_lines.extend(intermediate_lines)
                removed_pairs += 1
                i = j + 1
            else:
                # Keep the PUSH AX (no matching POP found)
                optimized_lines.append(lines[i])
                i += 1
        else:
            # Keep non-PUSH lines as is
            optimized_lines.append(lines[i])
            i += 1
    
    print(f"Removed {removed_pairs} PUSH AX / POP AX pairs")
    return '\n'.join(optimized_lines)

def remove_unused_labels(asm_code):
    """
    Remove labels that are not referenced by any jump instructions
    """
    lines = asm_code.strip().split('\n')
    
    # Step 1: Find all labels defined in the code
    defined_labels = set()
    label_pattern = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):')
    
    for line in lines:
        stripped = line.strip()
        match = label_pattern.match(stripped)
        if match:
            defined_labels.add(match.group(1))
    
    # Step 2: Find all labels referenced by jump/call instructions
    referenced_labels = set()
    jump_patterns = [
        re.compile(r'\b(?:JMP|JE|JNE|JL|JLE|JG|JGE|JZ|JNZ|JC|JNC|CALL)\s+([A-Za-z_][A-Za-z0-9_]*)\b', re.IGNORECASE),
        re.compile(r'\b(?:LOOP|LOOPE|LOOPNE|LOOPZ|LOOPNZ)\s+([A-Za-z_][A-Za-z0-9_]*)\b', re.IGNORECASE)
    ]
    
    for line in lines:
        for pattern in jump_patterns:
            matches = pattern.findall(line)
            for match in matches:
                referenced_labels.add(match)
    
    # Step 3: Determine unused labels
    unused_labels = defined_labels - referenced_labels
    removed_labels = len(unused_labels)
    
    # Step 4: Remove lines containing only unused labels
    cleaned_lines = []
    for line in lines:
        stripped = line.strip()
        match = label_pattern.match(stripped)
        
        if match:
            label_name = match.group(1)
            if label_name not in unused_labels:
                # Keep the label (it's used)
                cleaned_lines.append(line)
            # Skip unused labels
        else:
            # Keep non-label lines
            cleaned_lines.append(line)
    
    print(f"Removed {removed_labels} unused labels")
    return '\n'.join(cleaned_lines)

def remove_unreachable_code(asm_code):
    """
    Remove code that appears after RET instructions within functions
    """
    lines = asm_code.strip().split('\n')
    cleaned_lines = []
    i = 0
    removed_unreachable = 0
    
    while i < len(lines):
        current_line = lines[i].strip()
        cleaned_lines.append(lines[i])
        
        # Check if this is a RET instruction
        if re.match(r'^\s*RET\s*(\d+)?\s*(;.*)?$', current_line, re.IGNORECASE):
            i += 1
            # Skip lines until we find the next PROC or ENDP
            while i < len(lines):
                next_line = lines[i].strip()
                
                # Stop skipping if we find PROC, ENDP, or another label that's not unreachable
                if (re.match(r'^\s*\w+\s+PROC\s*$', next_line, re.IGNORECASE) or
                    re.match(r'^\s*\w+\s+ENDP\s*$', next_line, re.IGNORECASE) or
                    re.match(r'^\s*END\s+', next_line, re.IGNORECASE) or
                    next_line.startswith('.') or  # Directives like .DATA, .CODE
                    (next_line.endswith(':') and not re.match(r'^L\d+:', next_line))):  # Non-local labels
                    
                    cleaned_lines.append(lines[i])
                    break
                else:
                    # Skip this unreachable line
                    if next_line and not next_line.startswith(';'):
                        removed_unreachable += 1
                        print(f"Removing unreachable code: line {i+1}: {next_line}")
                
                i += 1
        else:
            i += 1
    
    print(f"Removed {removed_unreachable} lines of unreachable code")
    return '\n'.join(cleaned_lines)

def main():
    if len(sys.argv) != 2:
        print("Usage: python optimize_asm.py <assembly_file>")
        print("Example: python optimize_asm.py code.asm")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = input_file.replace('.asm', '_optimized.asm')
    
    try:
        # Read the assembly file
        with open(input_file, 'r') as f:
            asm_code = f.read()
        
        print("Step 1: Removing consecutive PUSH AX / POP AX pairs...")
        optimized_code = remove_push_pop_pairs(asm_code)
        
        # print("\nStep 2: Removing unreachable code after RET instructions...")
        # optimized_code = remove_unreachable_code(optimized_code)
        
        print("\nStep 2: Removing unused labels...")
        final_code = remove_unused_labels(optimized_code)
        
        # Write optimized code to output file
        with open(output_file, 'w') as f:
            f.write(final_code)
        
        print(f"\nOptimized assembly written to: {output_file}")
        
        # Show statistics
        original_lines = len(asm_code.strip().split('\n'))
        final_lines = len(final_code.strip().split('\n'))
        removed_lines = original_lines - final_lines
        
        print(f"\nStatistics:")
        print(f"Original lines: {original_lines}")
        print(f"Optimized lines: {final_lines}")
        print(f"Total removed: {removed_lines} lines ({removed_lines/original_lines*100:.1f}%)")
        
    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()