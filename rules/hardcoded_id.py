import re

# Matches exactly 15 or 18 character Salesforce IDs inside single quotes
# Example matched: '0015g00000ABCDe', '0065g00000XYZabcDE'
SF_ID_PATTERN = re.compile(
    r"'(?=[a-zA-Z0-9]{15}'|[a-zA-Z0-9]{18}')(?=.*\d)[a-zA-Z0-9]+'"
)

def check_hardcoded_id(context):
    violations = []

    for i, line in enumerate(context.lines):
        stripped = line.strip()

        # Ignore comments
        if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*'):
            continue

        # Ignore common safe Apex patterns (reduces false positives)
        if (
            '.put(' in line or
            'Map<' in line or
            'Label.' in line or
            'JSON.' in line
        ):
            continue

        if SF_ID_PATTERN.search(line):
            violations.append({
                "rule": "HARDCODED_ID",
                "line": i + 1,
                "message": "Hardcoded Salesforce ID detected. Avoid hardcoded IDs."
            })

    return violations
