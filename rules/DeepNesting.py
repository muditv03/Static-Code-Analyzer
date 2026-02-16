CONTROL_KEYWORDS = ('if', 'for', 'while', 'try', 'catch')

def check_deep_nesting(context, max_depth=3, if_grace_depth=1):
    violations = []

    control_stack = []   # stores control keyword types
    inside_method = False
    brace_balance = 0

    for i, line in enumerate(context.lines):
        stripped = line.strip()

        # Ignore comments
        if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*'):
            continue

        # Detect method start
        if (
            '(' in stripped and ')' in stripped and stripped.endswith('{')
            and not stripped.startswith(CONTROL_KEYWORDS + ('else',))
        ):
            inside_method = True
            brace_balance = 1
            control_stack.clear()
            continue

        if not inside_method:
            continue

        # Track method scope
        brace_balance += stripped.count('{')
        brace_balance -= stripped.count('}')

        if brace_balance <= 0:
            inside_method = False
            control_stack.clear()
            continue

        # Detect control block
        control_type = None
        for k in CONTROL_KEYWORDS:
            if stripped.startswith(k) and '{' in stripped:
                control_type = k
                break

        if control_type and not stripped.startswith('else'):
            control_stack.append(control_type)

            # ✅ NEW LOGIC
            allowed_depth = max_depth
            if control_type == 'if':
                allowed_depth += if_grace_depth  # allow 4 for if nesting

            if len(control_stack) > allowed_depth:
                violations.append({
                    "rule": "DEEP_NESTING",
                    "line": i + 1,
                    "severity": "MAJOR",
                    "message": (
                        f"Nesting depth {len(control_stack)} exceeds allowed limit "
                        f"({allowed_depth})."
                    )
                })

        # Pop control blocks
        if '}' in stripped:
            for _ in range(stripped.count('}')):
                if control_stack:
                    control_stack.pop()

    return violations
