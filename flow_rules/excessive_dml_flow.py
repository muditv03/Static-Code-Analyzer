# flow_rules/excessive_dml_flow.py
import re

LOOP_BLOCK = re.compile(r'<loops\b[\s\S]*?</loops>', re.IGNORECASE)
DML_PATTERN = re.compile(r'<record(Creates|Updates|Deletes)\b', re.IGNORECASE)
NAME_PATTERN = re.compile(r'<name>(.*?)</name>', re.IGNORECASE)

def check_excessive_dml_flow(context):
    violations = []
    text = context.code

    for loop_match in LOOP_BLOCK.finditer(text):
        loop_block = loop_match.group()
        dml_count = len(DML_PATTERN.findall(loop_block))

        if dml_count > 1:
            name_match = NAME_PATTERN.search(loop_block)
            loop_name = name_match.group(1) if name_match else "UnnamedLoop"

            line_no = text[:loop_match.start()].count("\n") + 1

            violations.append({
                "rule": "EXCESSIVE_DML_FLOW",
                "line": line_no,
                "severity": "CRITICAL",
                "message": f"Loop '{loop_name}' contains multiple DML operations ({dml_count})."
            })

    return violations
