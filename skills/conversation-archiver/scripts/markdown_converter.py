import json
import sys
import os

def convert_to_markdown(log_file, output_file, root_path=None, brain_path=None, home_path=None):
    if not os.path.exists(log_file):
        print(f"Error: Log file {log_file} not found.")
        return

    with open(log_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    markdown_content = "# Conversation History\n\n"

    # Prepare path replacements
    replacements = []
    if brain_path:
        replacements.append((os.path.abspath(brain_path), "$BRAIN_PATH"))
    if root_path:
        replacements.append((os.path.abspath(root_path), "."))
    if home_path:
        replacements.append((os.path.abspath(home_path), "~"))
    
    # Sort replacements by length of target (descending) to match longest paths first
    replacements.sort(key=lambda x: len(x[0]), reverse=True)

    def sanitize_paths(text):
        if not isinstance(text, str):
            return text
        for target, replacement in replacements:
            if target in text:
                text = text.replace(target, replacement)
        return text

    def format_arg_value(val):
        if not isinstance(val, str):
            return str(val)
        
        # Remove redundant quotes if present (double-encoded strings)
        if val.startswith('"') and val.endswith('"') and len(val) >= 2:
            try:
                # Try parsing as JSON to handle escapes
                decoded = json.loads(val)
                if isinstance(decoded, str):
                    val = decoded
            except:
                # Fallback to simple stripping
                val = val[1:-1]
        
        return sanitize_paths(val)

    def format_tool_args(args, indent="  "):
        if not isinstance(args, dict):
            return f"`{sanitize_paths(str(args))}`"
        
        lines = []
        for k, v in args.items():
            val = format_arg_value(v)
            if isinstance(val, str) and ("\n" in val or len(val) > 100):
                # Use code block for long or multi-line values
                # Ensure the code block is indented properly
                indented_val = "\n".join([f"{indent}    {l}" for l in val.splitlines()])
                lines.append(f"{indent}- **{k}**:\n{indent}  ```\n{val}\n{indent}  ```")
            else:
                lines.append(f"{indent}- **{k}**: `{val}`")
        return "\n".join(lines)

    for line in lines:
        try:
            entry = json.loads(line.strip())
            source = entry.get('source', 'UNKNOWN')
            msg_type = entry.get('type', 'UNKNOWN')
            content = entry.get('content', '')
            created_at = entry.get('created_at', '')

            content = sanitize_paths(content)

            if source == 'USER_EXPLICIT':
                markdown_content += f"## User ({created_at})\n\n"
                markdown_content += f"{content}\n\n"
            elif source == 'MODEL':
                if msg_type == 'PLANNER_RESPONSE':
                    tool_calls = entry.get('tool_calls', [])
                    if tool_calls:
                        markdown_content += f"## AI Tool Calls ({created_at})\n\n"
                        for tc in tool_calls:
                            name = tc.get('name')
                            args = tc.get('args', {})
                            formatted_args = format_tool_args(args)
                            markdown_content += f"- **{name}**:\n{formatted_args}\n"
                        markdown_content += "\n"
                else:
                    markdown_content += f"## AI ({created_at})\n\n"
                    markdown_content += f"{content}\n\n"
            
            markdown_content += "---\n\n"
        except json.JSONDecodeError:
            continue

    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(markdown_content)

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python markdown_converter.py <log_file> <output_file> [root_path] [brain_path] [home_path]")
    else:
        log = sys.argv[1]
        out = sys.argv[2]
        root = sys.argv[3] if len(sys.argv) > 3 else None
        brain = sys.argv[5] if len(sys.argv) > 5 else None
        home = sys.argv[6] if len(sys.argv) > 6 else None
        convert_to_markdown(log, out, root, brain, home)
