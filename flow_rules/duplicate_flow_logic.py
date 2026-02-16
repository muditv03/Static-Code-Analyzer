# flow_rules/duplicate_flow_logic.py
import re

ASSIGN_BLOCK = re.compile(r'<assignments\b[\s\S]*?</assignments>', re.IGNORECASE)
ASSIGN_ITEM = re.compile(
    r'<assignmentItems\b[\s\S]*?</assignmentItems>', re.IGNORECASE
)
ASSIGN_TO = re.compile(r'<assignToReference>(.*?)</assignToReference>', re.IGNORECASE)
OPERATOR = re.compile(r'<operator>(.*?)</operator>', re.IGNORECASE)
VALUE = re.compile(r'<value>(.*?)</value>', re.IGNORECASE)

def check_duplicate_flow_logic(context):
    violations = []
    text = context.code

    seen_signatures = set()
    reported_lines = set()  # store line numbers we already reported

    for assign_block_match in ASSIGN_BLOCK.finditer(text):
        assign_block = assign_block_match.group()

        for item_match in ASSIGN_ITEM.finditer(assign_block):
            item_block = item_match.group()

            assign_to_match = ASSIGN_TO.search(item_block)
            operator_match = OPERATOR.search(item_block)
            value_match = VALUE.search(item_block)

            # skip incomplete definitions
            if not assign_to_match or not operator_match or not value_match:
                continue

            signature = (
                assign_to_match.group(1).strip(),
                operator_match.group(1).strip(),
                value_match.group(1).strip()
            )

            # calculate line number
            line_no = text[:assign_block_match.start() + item_match.start()].count("\n") + 1

            if signature in seen_signatures and line_no not in reported_lines:
                violations.append({
                    "rule": "DUPLICATE_FLOW_LOGIC",
                    "line": line_no,
                    "severity": "MINOR",
                    "message": "Duplicate flow logic detected. Identical assignment logic found multiple times."
                })
                reported_lines.add(line_no)
            else:
                seen_signatures.add(signature)

    return violations
