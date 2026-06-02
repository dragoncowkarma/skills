import argparse
import json
import os
import sys
from datetime import datetime


class LogConverter:
    def __init__(self, root_path=None, brain_path=None, home_path=None, session_path=None):
        self.replacements = []
        if brain_path:
            self.replacements.append((os.path.abspath(brain_path), "$BRAIN_PATH"))
        if session_path:
            self.replacements.append((os.path.abspath(session_path), "$SESSION_PATH"))
        if root_path:
            self.replacements.append((os.path.abspath(root_path), "."))
        if home_path:
            abs_home = os.path.abspath(os.path.expanduser(home_path))
            self.replacements.append((abs_home, "~"))

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

        if val.startswith('"') and val.endswith('"') and len(val) >= 2:
            try:
                decoded = json.loads(val)
                if isinstance(decoded, str):
                    val = decoded
            except json.JSONDecodeError:
                val = val[1:-1]

        return self.sanitize_paths(val)

    def format_tool_args(self, args, indent="  "):
        if not isinstance(args, dict):
            return f"`{self.sanitize_paths(str(args))}`"

        lines = []
        for key, value in args.items():
            val = self.format_arg_value(value)
            if isinstance(val, str) and ("\n" in val or len(val) > 100):
                lines.append(f"{indent}- **{key}**:\n{indent}  ```\n{val}\n{indent}  ```")
            else:
                lines.append(f"{indent}- **{key}**: `{val}`")
        return "\n".join(lines)

    def read_entries(self, log_file):
        if not os.path.exists(log_file):
            print(f"Error: Log file {log_file} not found.")
            return None

        entries = []
        with open(log_file, "r", encoding="utf-8") as file:
            for line in file:
                line = line.strip()
                if not line:
                    continue
                try:
                    entries.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
        return entries

    def detect_format(self, entries):
        for entry in entries:
            if entry.get("type") in ("session_meta", "response_item", "turn_context"):
                return "codex"
            if "source" in entry:
                return "gemini"
        return "gemini"

    def content_to_text(self, content):
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts = []
            for item in content:
                if isinstance(item, str):
                    parts.append(item)
                elif isinstance(item, dict):
                    text = item.get("text") or item.get("content")
                    if text:
                        parts.append(text)
            return "\n".join(parts)
        if content is None:
            return ""
        return str(content)

    def convert(self, log_file, output_file, log_format="auto"):
        entries = self.read_entries(log_file)
        if entries is None:
            return False

        if log_format == "auto":
            log_format = self.detect_format(entries)

        if log_format == "codex":
            markdown_content = self.convert_codex_entries(entries)
        else:
            markdown_content = self.convert_gemini_entries(entries)

        with open(output_file, "w", encoding="utf-8") as file:
            file.write(markdown_content)

        return True

    def convert_gemini_entries(self, entries):
        markdown_content = (
            "# Conversation History\n\n"
            f"*Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*\n\n"
        )

        skipping_archiver = False
        for entry in entries:
            source = entry.get("source", "UNKNOWN")
            msg_type = entry.get("type", "UNKNOWN")
            content = entry.get("content", "")
            created_at = entry.get("created_at", "")
            tool_calls = entry.get("tool_calls", [])

            if source == "USER_EXPLICIT":
                skipping_archiver = "/conversation-archiver" in content

            if skipping_archiver:
                continue

            content = self.sanitize_paths(content)

            if source == "USER_EXPLICIT":
                markdown_content += f"## User ({created_at})\n\n{content}\n\n"
            elif source == "MODEL":
                if msg_type == "PLANNER_RESPONSE" or tool_calls:
                    if content:
                        markdown_content += f"## AI ({created_at})\n\n{content}\n\n"

                    if tool_calls:
                        markdown_content += "### Tool Calls\n\n"
                        for tool_call in tool_calls:
                            name = tool_call.get("name", "unknown_tool")
                            args = tool_call.get("args", {})
                            formatted_args = self.format_tool_args(args)
                            markdown_content += f"- **{name}**:\n{formatted_args}\n"
                        markdown_content += "\n"
                else:
                    markdown_content += f"## AI ({created_at})\n\n{content}\n\n"

            markdown_content += "---\n\n"

        return markdown_content

    def convert_codex_entries(self, entries):
        markdown_content = (
            "# Conversation History\n\n"
            f"*Generated on {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}*\n\n"
        )

        metadata = next(
            (entry.get("payload", {}) for entry in entries if entry.get("type") == "session_meta"),
            {},
        )
        if metadata:
            markdown_content += "## Session Metadata\n\n"
            for key in ("id", "timestamp", "cwd", "originator", "cli_version", "model_provider"):
                value = metadata.get(key)
                if value:
                    markdown_content += f"- **{key}**: `{self.sanitize_paths(str(value))}`\n"
            markdown_content += "\n---\n\n"

        for entry in entries:
            timestamp = entry.get("timestamp", "")
            entry_type = entry.get("type")
            payload = entry.get("payload", {})
            if not isinstance(payload, dict):
                continue

            if entry_type != "response_item":
                continue

            payload_type = payload.get("type")
            if payload_type == "message":
                role = payload.get("role", "")
                if role not in ("user", "assistant"):
                    continue
                content = self.sanitize_paths(self.content_to_text(payload.get("content", "")))
                if not content:
                    continue

                label = "User" if role == "user" else "AI"
                phase = payload.get("phase")
                if phase:
                    label += f" / {phase}"
                markdown_content += f"## {label} ({timestamp})\n\n{content}\n\n---\n\n"

            elif payload_type == "function_call":
                name = payload.get("name", "unknown_tool")
                args = payload.get("arguments", "")
                try:
                    args = json.loads(args)
                except (TypeError, json.JSONDecodeError):
                    pass
                formatted_args = self.format_tool_args(args)
                markdown_content += f"## Tool Call ({timestamp})\n\n- **{name}**:\n{formatted_args}\n\n---\n\n"

            elif payload_type == "function_call_output":
                output = self.sanitize_paths(str(payload.get("output", "")))
                call_id = payload.get("call_id", "unknown_call")
                if output:
                    markdown_content += (
                        f"## Tool Output ({timestamp})\n\n"
                        f"- **call_id**: `{call_id}`\n\n"
                        f"```\n{output}\n```\n\n---\n\n"
                    )

        return markdown_content


def main():
    parser = argparse.ArgumentParser(description="Convert JSON conversation logs to Markdown.")
    parser.add_argument("log_file", help="Path to the input JSON log file")
    parser.add_argument("output_file", help="Path to the output Markdown file")
    parser.add_argument("--root", help="Project root path for normalization")
    parser.add_argument("--brain", help="Brain path for normalization ($BRAIN_PATH)")
    parser.add_argument("--session", help="Codex session path for normalization ($SESSION_PATH)")
    parser.add_argument("--home", help="Home path for normalization (~)")
    parser.add_argument(
        "--format",
        choices=["auto", "gemini", "codex"],
        default="auto",
        help="Input log format",
    )

    args = parser.parse_args()

    converter = LogConverter(
        root_path=args.root,
        brain_path=args.brain,
        home_path=args.home,
        session_path=args.session,
    )
    if converter.convert(args.log_file, args.output_file, log_format=args.format):
        print(f"Successfully converted {args.log_file} to {args.output_file}")
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
