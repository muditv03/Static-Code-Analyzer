import re
from collections import defaultdict

VARIABLE_DECL_PATTERN = re.compile(
    r'\b(?:String|Integer|Decimal|Boolean|Id|Date|Datetime|Long|Double)\s+(\w+)\s*(=|;)'
)

def check_unused_variables(context):
    usage_count = defaultdict(int)
    declared_vars = {}

    for i, line in enumerate(context.lines):
        decl = VARIABLE_DECL_PATTERN.search(line)
        if decl:
            var = decl.group(1)
            declared_vars[var] = i + 1

        for var in declared_vars.keys():
            if re.search(r'\b' + re.escape(var) + r'\b', line):
                usage_count[var] += 1

    violations = []

    for var, line_no in declared_vars.items():
        if usage_count[var] <= 1:
            violations.append({
                "rule": "UNUSED_VARIABLE",
                "line": line_no,
                "severity": "MINOR",
                "message": f"Variable '{var}' is declared but never used."
            })

    return violations
