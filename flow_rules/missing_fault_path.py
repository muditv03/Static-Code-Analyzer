# flow_rules/missing_fault_path.py
import re

RECORD_OP_PATTERN = re.compile(r'<record(Creates|Updates|Deletes)>', re.IGNORECASE)
FAULT_PATTERN = re.compile(r'<faultConnector>', re.IGNORECASE)

def check_missing_fault_path(context):
    violations = []

    for i, line in enumerate(context.lines):
        if RECORD_OP_PATTERN.search(line):
            # Check next 10 lines for faultConnector
            block_lines = context.lines[i:i+10]
            if not any(FAULT_PATTERN.search(l) for l in block_lines):
                violations.append({
                    "rule": "MISSING_FAULT_PATH",
                    "line": i + 1,
                    "severity": "CRITICAL",
                    "message": f"Flow record operation does not define a fault path."
                })

    return violations
