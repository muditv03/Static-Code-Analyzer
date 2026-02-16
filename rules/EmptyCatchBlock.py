import re

EMPTY_CATCH_PATTERN = re.compile(
    r'catch\s*\(\s*\w+Exception\s+\w+\s*\)\s*\{\s*\}',
    re.DOTALL
)

def check_empty_catch(context):
    violations = []

    full_text = "\n".join(context.lines)

    for match in EMPTY_CATCH_PATTERN.finditer(full_text):
        line_no = full_text[:match.start()].count("\n") + 1
        violations.append({
            "rule": "EMPTY_CATCH_BLOCK",
            "line": line_no,
            "severity": "MAJOR",
            "message": "Empty catch block detected. Exceptions must be handled or logged."
        })

    return violations
