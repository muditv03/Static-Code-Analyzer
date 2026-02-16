# flow_rules/nested_loops_in_flow.py
def check_nested_loops_in_flow(context):
    violations = []
    ns = context.namespace
    root = context.root

    outer_loops = root.findall(".//sf:loops", ns)

    for loop in outer_loops:
        nested_loops = loop.findall(".//sf:loops", ns)
        if nested_loops:
            loop_name_elem = loop.find("sf:name", ns)
            loop_name = loop_name_elem.text if loop_name_elem is not None else "UnnamedLoop"
            violations.append({
                "rule": "NESTED_LOOPS_IN_FLOW",
                "line": 1,  # we can improve using get_element_line_no
                "severity": "CRITICAL",
                "message": f"Loop '{loop_name}' contains nested loops. Refactor recommended."
            })
    return violations
