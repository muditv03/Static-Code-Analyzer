# flow_rules/flow_missing_description.py
def check_flow_missing_description(context):
    """
    Detects if the Flow description is missing or empty.
    """
    violations = []
    ns = context.namespace
    root = context.root

    desc_elem = root.find("sf:description", ns)

    if desc_elem is None or (desc_elem.text is None) or not desc_elem.text.strip():
        # Use line number like in other rules
        try:
            with open(context.file_path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            line_no = next((i+1 for i, l in enumerate(lines) if "<description>" in l), "N/A")
        except Exception:
            line_no = "N/A"

        violations.append({
            "rule": "FLOW_MISSING_DESCRIPTION",
            "line": line_no,
            "severity": "MAJOR",
            "message": "Flow description is missing or empty."
        })

    return violations
