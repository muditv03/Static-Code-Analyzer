import os
from engine.runner import run_analysis

SUPPORTED_EXTENSIONS = (
    ".cls",
    ".trigger",
    ".flow-meta.xml",
    ".js",
    ".html",
    ".css",
    ".xml"
)

def is_supported_file(filename):
    return filename.endswith(SUPPORTED_EXTENSIONS)

def analyze_project(folder_path):
    results = []

    for root, dirs, files in os.walk(folder_path):
        for filename in files:

            if filename.startswith(".") or filename.startswith("._"):
                continue

            if not is_supported_file(filename):
                continue

            file_path = os.path.join(root, filename)
            violations = run_analysis(file_path)

            results.append({
                "file_name": filename,
                "total_issues": len(violations),
                "violations": violations
            })

    return results