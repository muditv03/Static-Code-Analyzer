# flow_rules/decision_without_default.py
import re

DECISION_BLOCK = re.compile(r'<decisions\b[\s\S]*?</decisions>', re.IGNORECASE)
DECISION_NAME = re.compile(r'<name>(.*?)</name>', re.IGNORECASE)
RULES_BLOCK = re.compile(r'<rules\b[\s\S]*?</rules>', re.IGNORECASE)
IS_DEFAULT = re.compile(r'<isDefault>(.*?)</isDefault>', re.IGNORECASE)

def check_decision_without_default(context):
    violations = []
    text = context.code

    for decision_match in DECISION_BLOCK.finditer(text):
        decision_block = decision_match.group()

        # Get decision name
        name_match = DECISION_NAME.search(decision_block)
        decision_name = name_match.group(1) if name_match else "UnnamedDecision"

        # Check if any rule is default
        has_default = False
        for rule_match in RULES_BLOCK.finditer(decision_block):
            is_default_match = IS_DEFAULT.search(rule_match.group())
            if is_default_match and is_default_match.group(1).strip().lower() == "true":
                has_default = True
                break

        if not has_default:
            line_no = text[:decision_match.start()].count("\n") + 1
            violations.append({
                "rule": "DECISION_WITHOUT_DEFAULT",
                "line": line_no,
                "severity": "MAJOR",
                "message": f"Decision '{decision_name}' does not define a default outcome."
            })

    return violations
