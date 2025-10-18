#!/usr/bin/env python3
import json, glob, shutil, time, os, sys
from jsonschema import validate, ValidationError

SPACE_DIR = os.path.dirname(__file__)
SCHEMA_FILE = os.path.join(SPACE_DIR, 'config', 'copilot-schema.json')
# Only validate config files, not package.json or other project files
JSON_FILES = [f for f in glob.glob(os.path.join(SPACE_DIR, 'copilot', '*.json')) 
              if not f.endswith('package.json') and not f.endswith('package-lock.json')]

def log_audit(message):
    with open(os.path.join(SPACE_DIR,'audit.log'), 'a') as f:
        f.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S')} {message}\n")

def load_schema():
    return json.load(open(SCHEMA_FILE))

def backup(file):
    base = os.path.basename(file)
    timestamp = time.strftime('%Y%m%d%H%M%S')
    bak = os.path.join(SPACE_DIR, f"backup-{base}-{timestamp}.json")
    shutil.copy(file, bak)
    return bak

def main():
    schema = load_schema()
    for jf in JSON_FILES:
        data = json.load(open(jf))
        try:
            validate(instance=data, schema=schema)
        except ValidationError as e:
            print(f"Schema validation error in {jf}: {e.message}")
            sys.exit(1)
        bak = backup(jf)
        log_audit(f"Validated & backed up {jf} -> {bak}")
    print("All JSON files validated and backed up.")
    log_audit("verify_jsons.py completed successfully.")

if __name__=="__main__":
    main()