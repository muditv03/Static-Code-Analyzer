# flow_rules/loop_without_assignment.py
import re

LOOP_BLOCK = re.compile(r'<loops\b[\s\S]*?</loops>', re.IGNORECASE)
ASSIGN_PATTERN = re.compile(r'<assignments\b', re.IGNORECASE)
DML_PATTERN = re.compile(r'<record(Creates|Updates|Deletes)\b', re.IGNORECASE)
NAME_PATTERN = re.compile(r'<name>(.*?)</name>', re.IGNORECASE)

def check_loop_without_assignment(context):
    violations = []
    text = context.code

    for loop_match in LOOP_BLOCK.finditer(text):
        loop_block = loop_match.group()

        if not ASSIGN_PATTERN.search(loop_block) and not DML_PATTERN.search(loop_block):
            name_match = NAME_PATTERN.search(loop_block)
            loop_name = name_match.group(1) if name_match else "UnnamedLoop"

            line_no = text[:loop_match.start()].count("\n") + 1

            violations.append({
                "rule": "LOOP_WITHOUT_ASSIGNMENT",
                "line": line_no,
                "severity": "MAJOR",
                "message": f"Loop '{loop_name}' does not perform any assignments or record operations."
            })

    return violations
