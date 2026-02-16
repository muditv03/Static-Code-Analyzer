# flow_rules/unused_flow_variable.py
def check_unused_flow_variable(context):
    violations = []
    ns = context.namespace
    root = context.root
    full_text = context.code

    variables = root.findall(".//sf:variables", ns)
    for var in variables:
        var_name_elem = var.find("sf:name", ns)
        if var_name_elem is None:
            continue
        var_name = var_name_elem.text

        if var_name not in full_text.replace(var_name, "", 1):  # simple check
            violations.append({
                "rule": "UNUSED_FLOW_VARIABLE",
                "line": 1,  # could improve with get_element_line_no
                "severity": "MAJOR",
                "message": f"Flow variable '{var_name}' is declared but never used."
            })
    return violations
