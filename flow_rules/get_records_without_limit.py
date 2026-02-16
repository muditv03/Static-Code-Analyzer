# flow_rules/get_records_without_limit.py
def check_get_records_without_limit(context):
    violations = []
    ns = context.namespace
    root = context.root

    lookups = root.findall(".//sf:recordLookups", ns)
    for lookup in lookups:
        first_only_elem = lookup.find("sf:getFirstRecordOnly", ns)
        limit_elem = lookup.find("sf:limit", ns)

        if (first_only_elem is None or first_only_elem.text.lower() == "false") and limit_elem is None:
            name_elem = lookup.find("sf:name", ns)
            lookup_name = name_elem.text if name_elem is not None else "UnnamedLookup"
            violations.append({
                "rule": "GET_RECORDS_WITHOUT_LIMIT",
                "line": 1,  # could improve with get_element_line_no
                "severity": "MAJOR",
                "message": f"Record lookup '{lookup_name}' does not have a limit or getFirstRecordOnly set."
            })
    return violations
