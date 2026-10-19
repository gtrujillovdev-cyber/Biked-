import json
import re

def parse_geometry_table(text):
    """
    Parses a typical geometry table text.
    Expects format like:
    Size | 51 | 54 | 56 | 58
    Stack | 510 | 530 | 550 | 570
    Reach | 370 | 380 | 390 | 400
    """
    lines = [l.strip() for l in text.split('\n') if l.strip()]
    
    sizes = []
    stacks = []
    reaches = []
    
    for line in lines:
        parts = re.split(r'\s*\|\s*|\t|\s{2,}', line)
        header = parts[0].lower()
        values = parts[1:]
        
        if 'size' in header or 'talla' in header:
            sizes = values
        elif 'stack' in header:
            stacks = [float(v.replace('mm', '').strip()) for v in values]
        elif 'reach' in header:
            reaches = [float(v.replace('mm', '').strip()) for v in values]
            
    geometries = []
    for i in range(len(sizes)):
        geometries.append({
            "size": sizes[i],
            "stack": stacks[i] if i < len(stacks) else 0,
            "reach": reaches[i] if i < len(reaches) else 0
        })
        
    return geometries

# Example Usage:
table_data = """
Size | 47 | 51 | 54 | 56 | 58 | 61
Stack (mm) | 506 | 527 | 548 | 569 | 592 | 614
Reach (mm) | 373 | 380 | 386 | 393 | 400 | 407
"""

if __name__ == "__main__":
    result = parse_geometry_table(table_data)
    print(json.dumps(result, indent=2))
