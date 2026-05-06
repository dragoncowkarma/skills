import json
import sys
import os

def convert_to_markdown(log_file, output_file):
    if not os.path.exists(log_file):
        print(f"Error: Log file {log_file} not found.")
        return

    with open(log_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    markdown_content = "# Conversation History\n\n"

    for line in lines:
        try:
            entry = json.loads(line.strip())
            source = entry.get('source', 'UNKNOWN')
            msg_type = entry.get('type', 'UNKNOWN')
            content = entry.get('content', '')
            created_at = entry.get('created_at', '')

            if source == 'USER_EXPLICIT':
                markdown_content += f"## User ({created_at})\n\n"
                markdown_content += f"{content}\n\n"
            elif source == 'MODEL':
                if msg_type == 'PLANNER_RESPONSE':
                    # Skip internal planner tool calls in the main flow if they are too verbose
                    # or format them nicely.
                    tool_calls = entry.get('tool_calls', [])
                    if tool_calls:
                        markdown_content += f"## AI Tool Calls ({created_at})\n\n"
                        for tc in tool_calls:
                            markdown_content += f"- **{tc.get('name')}**: `{tc.get('args')}`\n"
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
        print("Usage: python markdown_converter.py <log_file> <output_file>")
    else:
        convert_to_markdown(sys.argv[1], sys.argv[2])
