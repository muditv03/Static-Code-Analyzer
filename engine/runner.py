from engine.context import AnalysisContext
from engine.flow_context import FlowContext
from utils.file_loader import load_file

# Apex rules
from rules.soql_in_loop import check_soql_in_loop
from rules.DeepNesting import check_deep_nesting
from rules.dml_in_loop import check_dml_in_loop
from rules.EmptyCatchBlock import check_empty_catch
from rules.UnusedVariable import check_unused_variables
from rules.hardcoded_id import check_hardcoded_id

# Flow rules
from flow_rules.missing_fault_path import check_missing_fault_path
from flow_rules.hardcoded_id_flow import check_hardcoded_id_flow
from flow_rules.excessive_dml_flow import check_excessive_dml_flow
from flow_rules.loop_without_assignment import check_loop_without_assignment
from flow_rules.flow_missing_description import check_flow_missing_description
from flow_rules.nested_loops_in_flow import check_nested_loops_in_flow
from flow_rules.unused_flow_variable import check_unused_flow_variable
from flow_rules.get_records_without_limit import check_get_records_without_limit
from flow_rules.decision_without_default import check_decision_without_default
from flow_rules.duplicate_flow_logic import check_duplicate_flow_logic


def run_analysis(file_path):
    violations = []

    # Apex analysis
    if file_path.endswith(".cls"):
        code = load_file(file_path)
        context = AnalysisContext(code)

        violations.extend(check_soql_in_loop(context))
        violations.extend(check_dml_in_loop(context))
        violations.extend(check_hardcoded_id(context))
        violations.extend(check_deep_nesting(context))
        violations.extend(check_empty_catch(context))
        violations.extend(check_unused_variables(context))

    # Flow analysis
    elif file_path.endswith(".flow-meta.xml"):
        context = FlowContext(file_path)
        violations.extend(check_missing_fault_path(context))
        violations.extend(check_hardcoded_id_flow(context))
        violations.extend(check_excessive_dml_flow(context))
        violations.extend(check_loop_without_assignment(context))
        violations.extend(check_flow_missing_description(context))
        violations.extend(check_nested_loops_in_flow(context))
        violations.extend(check_unused_flow_variable(context))
        violations.extend(check_get_records_without_limit(context))
        violations.extend(check_decision_without_default(context))
        violations.extend(check_duplicate_flow_logic(context))
  

    else:
        print("❌ Unsupported file type")

    return violations
