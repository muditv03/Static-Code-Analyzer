import re

# Salesforce ID: 15 or 18 chars, must start with an uppercase letter or number
SF_ID_PATTERN = re.compile(r"\b[a-zA-Z0-9]{15,18}\b")

# Tags where hardcoded IDs are actually dangerous
VALUE_TAGS = (
    "<value>",
    "<stringValue>",
    "<inputValue>",
    "<rightValue>",
    "<leftValue>",
)

# Tags to ignore completely
IGNORE_CONTEXT = (
    "<processMetadataValues>",
    "<connector",
    "<object>",
    "<name>",
    "<label>",
    "<description>",
)

def check_hardcoded_id_flow(context):
    violations = []
    reported_lines = set()

    for i, line in enumerate(context.lines):
        line_no = i + 1
        stripped = line.strip()

        # Skip comments or empty lines
        if not stripped or stripped.startswith("<!--"):
            continue

        # Skip known safe metadata
        if any(tag in stripped for tag in IGNORE_CONTEXT):
            continue

        # Only check value-carrying tags
        if not any(tag in stripped for tag in VALUE_TAGS):
            continue

        # Find Salesforce IDs
        for match in SF_ID_PATTERN.finditer(stripped):
            sf_id = match.group()

            # Avoid false positives like "000000000000000"
            if sf_id.isdigit():
                continue

            if line_no in reported_lines:
                continue

            reported_lines.add(line_no)

            violations.append({
                "rule": "HARDCODED_ID_IN_FLOW",
                "line": line_no,
                "severity": "MAJOR",
                "message": f"Hardcoded Salesforce ID detected in Flow: {sf_id}"
            })

    return violations
