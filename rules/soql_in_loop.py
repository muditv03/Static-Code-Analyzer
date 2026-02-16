import re

def check_soql_in_loop(context):
    violations = []
    inside_loop = False

    for i, line in enumerate(context.lines):
        if re.search(r'\bfor\s*\(.*\)', line):
            inside_loop = True

        if inside_loop and re.search(r'\bSELECT\b', line, re.IGNORECASE):
            violations.append({
                "rule": "SOQL_IN_LOOP",
                "line": i + 1,
                "message": "SOQL query inside loop"
            })

        if inside_loop and "}" in line:
            inside_loop = False

    return violations
