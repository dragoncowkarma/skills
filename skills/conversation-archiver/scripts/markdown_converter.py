import json
import argparse
import os
import sys
from datetime import datetime

class LogConverter:
    def __init__(self, root_path=None, brain_path=None, home_path=None):
        self.replacements = []
        if brain_path:
            self.replacements.append((os.path.abspath(brain_path), "$BRAIN_PATH"))
        if root_path:
            self.replacements.append((os.path.abspath(root_path), "."))
        if home_path:
            # Expand ~ if provided as a string like '~'
            abs_home = os.path.abspath(os.path.expanduser(home_path))
            self.replacements.append((abs_home, "~"))
        
        # Sort replacements by length of target (descending) to match longest paths first
        self.replacements.sort(key=lambda x: len(x[0]), reverse=True)

    def sanitize_paths(self, text):
        if not isinstance(text, str):
            return text
        for target, replacement in self.replacements:
            if target in text:
                text = text.replace(target, replacement)
        return text

    def format_arg_value(self, val):
        if not isinstance(val, str):
            return str(val)
        
        # Remove redundant quotes if present (double-encoded strings)
        if val.startswith('"') and val.endswith('"') and len(val) >= 2:
            try:
                decoded = json.loads(val)
                if isinstance(decoded, str):
                    val = decoded
            except:
                val = val[1:-1]
        
        return self.sanitize_paths(val)

    def format_tool_args(self, args, indent="  "):
        if not isinstance(args, dict):
            return f"`{self.sanitize_paths(str(args))}`"
        
        lines = []
        for k, v in args.items():
            val = self.format_arg_value(v)
            if isinstance(val, str) and ("\n" in val or len(val) > 100):
                # Use code block for long or multi-line values
                lines.append(f"{indent}- **{k}**:\n{indent}  ```\n{val}\n{indent}  ```")
            else:
                lines.append(f"{indent}- **{k}**: `{val}`")
        return "\n".join(lines)

    def convert(self, log_file, output_file, api_data_file=None):
        if not os.path.exists(log_file):
            print(f"Error: Log file {log_file} not found.")
            return False

        api_steps = {}
        if api_data_file and os.path.exists(api_data_file):
            try:
                with open(api_data_file, 'r') as f:
                    api_data = json.load(f)
                    for step in api_data.get('steps', []):
                        idx = step.get('step_index')
                        if idx is not None:
                            api_steps[idx] = step
                print(f"[*] Loaded {len(api_steps)} steps from API data for merging.")
            except Exception as e:
                print(f"Warning: Failed to load API data: {e}")

        markdown_content = f"# Conversation History\n\n*Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*\n\n"

        skipping_archiver = False
        with open(log_file, 'r', encoding='utf-8') as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    entry = json.loads(line)
                    source = entry.get('source', 'UNKNOWN')
                    msg_type = entry.get('type', 'UNKNOWN')
                    content = entry.get('content', '')
                    created_at = entry.get('created_at', '')
                    tool_calls = entry.get('tool_calls', [])
                    step_index = entry.get('step_index')

                    if source == 'USER_EXPLICIT':
                        if '/conversation-archiver' in content:
                            skipping_archiver = True
                        else:
                            skipping_archiver = False

                    if skipping_archiver:
                        continue

                    if entry.get('status') == 'TRUNCATED':
                        markdown_content += "> [!WARNING]\n> This step was TRUNCATED in the original log. "
                        if step_index in api_steps:
                            markdown_content += "Full content recovered from API.\n\n"
                        else:
                            markdown_content += "Use `--recover` to fetch full content.\n\n"

                    # If we have API data for this step, prioritize it
                    if step_index is not None and step_index in api_steps:
                        api_entry = api_steps[step_index]
                        content = api_entry.get('content', content)
                        tool_calls = api_entry.get('tool_calls', tool_calls)

                    content = self.sanitize_paths(content)

                    if source == 'USER_EXPLICIT':
                        markdown_content += f"## 👤 User ({created_at})\n\n"
                        markdown_content += f"{content}\n\n"
                    elif source == 'MODEL':
                        if msg_type == 'PLANNER_RESPONSE' or tool_calls:
                            if content:
                                markdown_content += f"## 🤖 AI ({created_at})\n\n"
                                markdown_content += f"{content}\n\n"
                            
                            if tool_calls:
                                markdown_content += "### 🔧 Tool Calls\n\n"
                                for tc in tool_calls:
                                    name = tc.get('name', 'unknown_tool')
                                    args = tc.get('args', {})
                                    formatted_args = self.format_tool_args(args)
                                    markdown_content += f"- **{name}**:\n{formatted_args}\n"
                                markdown_content += "\n"
                        else:
                            markdown_content += f"## 🤖 AI ({created_at})\n\n"
                            markdown_content += f"{content}\n\n"
                    
                    markdown_content += "---\n\n"
                except json.JSONDecodeError:
                    continue

        with open(output_file, 'w', encoding='utf-8') as f:
            f.write(markdown_content)
        
        return True

def main():
    parser = argparse.ArgumentParser(description="Convert JSON conversation logs to Markdown.")
    parser.add_argument("log_file", help="Path to the input JSON log file")
    parser.add_argument("output_file", help="Path to the output Markdown file")
    parser.add_argument("--root", help="Project root path for normalization")
    parser.add_argument("--brain", help="Brain path for normalization ($BRAIN_PATH)")
    parser.add_argument("--home", help="Home path for normalization (~)")
    parser.add_argument("--api-data", help="Path to API recovered JSON data")

    args = parser.parse_args()

    converter = LogConverter(root_path=args.root, brain_path=args.brain, home_path=args.home)
    if converter.convert(args.log_file, args.output_file, api_data_file=args.api_data):
        print(f"Successfully converted {args.log_file} to {args.output_file}")
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
