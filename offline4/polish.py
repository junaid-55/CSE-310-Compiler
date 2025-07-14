#!/usr/bin/env python3

import re
import sys

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
    
    return '\n'.join(cleaned_lines)

def main():
    if len(sys.argv) != 2:
        print("Usage: python remove_unused_labels.py <assembly_file>")
        print("Example: python remove_unused_labels.py code.asm")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = input_file.replace('.asm', '_cleaned.asm')
    
    try:
        # Read the assembly file
        with open(input_file, 'r') as f:
            asm_code = f.read()
        
        # Remove unused labels
        cleaned_code = remove_unused_labels(asm_code)
        
        # Write cleaned code to output file
        with open(output_file, 'w') as f:
            f.write(cleaned_code)
        
        print(f"Cleaned assembly written to: {output_file}")
        
        # Show statistics
        original_lines = len(asm_code.strip().split('\n'))
        cleaned_lines = len(cleaned_code.strip().split('\n'))
        removed_lines = original_lines - cleaned_lines
        
        print(f"Original lines: {original_lines}")
        print(f"Cleaned lines: {cleaned_lines}")
        print(f"Removed {removed_lines} unused label lines")
        
    except FileNotFoundError:
        print(f"Error: File '{input_file}' not found")
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()