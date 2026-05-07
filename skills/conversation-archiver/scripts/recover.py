import os
import sys
import json
import argparse
import shutil
from datetime import datetime

try:
    from antigravity_history.api import call_api
except ImportError:
    call_api = None

def get_default_port():
    return 61749

def get_default_token():
    # Attempt to read from installation_id as a fallback
    token_path = os.path.expanduser("~/.gemini/antigravity/installation_id")
    if os.path.exists(token_path):
        with open(token_path, 'r') as f:
            return f.read().strip()
    return ""

def recover_api(cascade_id, port, token, output_file=None):
    if not call_api:
        print("Error: antigravity-history library not found. Run 'pip install antigravity-history'")
        return None

    print(f"[*] Attempting API recovery for cascade: {cascade_id}")
    print(f"[*] Using port: {port}, token: {token[:8]}...")

    try:
        result = call_api(port, token, "GetCascadeTrajectorySteps", {
            "cascadeId": cascade_id,
            "verbosity": 2
        })
        
        if not result:
            print("[-] API returned empty result. Check port and token.")
            return None

        steps = result.get("steps", [])
        print(f"[+] Successfully retrieved {len(steps)} steps via API.")
        
        if output_file:
            with open(output_file, 'w', encoding='utf-8') as f:
                json.dump(result, f, indent=2)
            print(f"[+] API response saved to {output_file}")
        
        return result
    except Exception as e:
        print(f"[-] API call failed: {e}")
        return None

def inject_pb(source_pb, target_id):
    conv_dir = os.path.expanduser("~/.gemini/antigravity/conversations/")
    target_pb = os.path.join(conv_dir, f"{target_id}.pb")
    
    if not os.path.exists(source_pb):
        print(f"[-] Source .pb file not found: {source_pb}")
        return False
    
    if not os.path.exists(target_pb):
        print(f"[-] Target conversation ID {target_id} not found in {conv_dir}")
        return False

    # Backup target
    backup_path = target_pb + ".bak_" + datetime.now().strftime("%Y%m%d_%H%M%S")
    shutil.copy2(target_pb, backup_path)
    print(f"[*] Backed up target to {backup_path}")

    # Inject
    shutil.copy2(source_pb, target_pb)
    print(f"[+] Successfully injected {source_pb} into {target_id}.pb")
    print("[!] Please restart Antigravity IDE to see the changes.")
    return True

def main():
    parser = argparse.ArgumentParser(description="Recovery tools for Antigravity conversations.")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    # API Recovery command
    api_parser = subparsers.add_parser("api", help="Recover conversation via API")
    api_parser.add_argument("cascade_id", help="The cascade ID to recover")
    api_parser.add_argument("--port", type=int, default=get_default_port(), help="API port")
    api_parser.add_argument("--token", default=get_default_token(), help="CSRF token")
    api_parser.add_argument("--output", help="Output JSON file for the API response")

    # Injection command
    inject_parser = subparsers.add_parser("inject", help="Inject a .pb file into an existing conversation")
    inject_parser.add_argument("source_pb", help="Path to the source .pb file to recover")
    inject_parser.add_argument("target_id", help="The dummy conversation ID to overwrite")

    args = parser.parse_args()

    if args.command == "api":
        recover_api(args.cascade_id, args.port, args.token, args.output)
    elif args.command == "inject":
        inject_pb(args.source_pb, args.target_id)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
