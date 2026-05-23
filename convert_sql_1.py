import re

def convert_line(line):
    line = line.strip()
    if not line: return ""
    
    # Skip comments
    if line.startswith("--"): return ""
    
    # Remove comments in line
    line = re.sub(r" COMMENT '.*?'", "", line)
    
    # Types
    line = re.sub(r"int\(\d+\) NOT NULL AUTO_INCREMENT", "INTEGER PRIMARY KEY AUTOINCREMENT", line)
    line = re.sub(r"int\(\d+\)", "INTEGER", line)
    line = re.sub(r"tinyint\(\d+\)", "INTEGER", line)
    line = re.sub(r"varchar\(\d+\)", "TEXT", line)
    line = re.sub(r"decimal\(\d+,\d+\)", "REAL", line)
    line = re.sub(r"longtext", "TEXT", line)
    line = re.sub(r"text", "TEXT", line)
    
    # Remove keys and constraints
    if line.startswith("PRIMARY KEY"): return ""
    if line.startswith("KEY"): return ""
    if line.startswith("UNIQUE KEY"):
        m = re.match(r"UNIQUE KEY `\w+` \((.*?)\)", line)
        if m:
            return f"UNIQUE ({m.group(1)}),"
        return ""
    if line.startswith("CONSTRAINT"): return ""
    
    return line

def convert_file(input_path, output_path):
    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Split into statements
    statements = content.split(';')
    new_statements = []
    
    for stmt in statements:
        if not stmt.strip(): continue
        
        lines = stmt.split('\n')
        new_lines = []
        is_create_table = False
        
        for line in lines:
            line = line.strip()
            if not line: continue
            
            if line.startswith("CREATE TABLE"):
                is_create_table = True
                new_lines.append(line)
                continue
            
            if line.startswith(") ENGINE"):
                if is_create_table:
                    new_lines.append(");")
                    continue
            
            if is_create_table:
                conv = convert_line(line)
                if conv:
                    new_lines.append(conv)
            else:
                # Other statements (INSERT, etc)
                line = line.replace("UNIX_TIMESTAMP()", "strftime('%s', 'now')")
                new_lines.append(line)
        
        # Post-process CREATE TABLE to fix commas
        if is_create_table:
            # Filter empty lines
            filtered = [l for l in new_lines if l.strip()]
            if not filtered: continue
            
            # Identify the closing parenthesis
            closing_idx = -1
            for i, l in enumerate(filtered):
                if l.startswith(");"):
                    closing_idx = i
                    break
            
            if closing_idx != -1:
                # The line before closing_idx should remove trailing comma
                prev_idx = closing_idx - 1
                if prev_idx >= 0:
                    filtered[prev_idx] = filtered[prev_idx].rstrip(',')
            
            new_statements.append("\n".join(filtered))
        else:
            # Insert statements
            if new_lines:
                new_statements.append("\n".join(new_lines) + ";")

    with open(output_path, 'w', encoding='utf-8') as f:
        f.write("\n\n".join(new_statements))

if __name__ == "__main__":
    convert_file("database.sql", "database_sqlite.sql")
