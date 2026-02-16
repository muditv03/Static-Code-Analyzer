import sys
from engine.runner import run_analysis

def main():
    if len(sys.argv) < 3:
        print("Usage: apex-analyzer analyze <file>")
        sys.exit(1)

    command = sys.argv[1]
    file_path = sys.argv[2]

    if command != "analyze":
        print("Unknown command")
        sys.exit(1)

    violations = run_analysis(file_path)

    if violations:
        print(f"\n❌ FAILED ({len(violations)} issues)\n")
        for v in violations:
            print(f"[{v['rule']}]")
            print(f"Line {v['line']}: {v['message']}\n")
        sys.exit(1)
    else:
        print("\n✅ PASSED (0 issues)\n")
        sys.exit(0)

if __name__ == "__main__":
    main()
