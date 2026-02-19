from fastapi import FastAPI, UploadFile, File, HTTPException
import os
import zipfile
import shutil
from analyzer import run_analysis

app = FastAPI()

UPLOAD_DIR = "uploads"
EXTRACT_DIR = "extracted"

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(EXTRACT_DIR, exist_ok=True)


@app.post("/analyze-folder")
async def analyze_folder(file: UploadFile = File(...)):

    # Validate ZIP
    if not file.filename.endswith(".zip"):
        raise HTTPException(status_code=400, detail="Only ZIP files allowed")

    zip_path = os.path.join(UPLOAD_DIR, file.filename)

    # Save uploaded ZIP
    with open(zip_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Prepare extraction path
    extract_path = os.path.join(
        EXTRACT_DIR, file.filename.replace(".zip", "")
    )

    # Clean old extraction if exists
    if os.path.exists(extract_path):
        shutil.rmtree(extract_path)

    os.makedirs(extract_path, exist_ok=True)

    # Extract ZIP (skip __MACOSX)
    with zipfile.ZipFile(zip_path, 'r') as zip_ref:
        for member in zip_ref.namelist():
            if not member.startswith("__MACOSX/"):
                zip_ref.extract(member, extract_path)

    violations = []

    try:
        # Walk through extracted folder
        file_results = []
        total_issues = 0
        major_count = 0
        minor_count = 0
        critical_count = 0
        for root, dirs, files in os.walk(extract_path):

            dirs[:] = [d for d in dirs if not d.startswith("__MACOSX")]

            for filename in files:
                file_path = os.path.join(root, filename)
                print(f"Analyzing: {file_path}")
                if filename.startswith(".") or filename.startswith("._"):
                    continue

                if filename.endswith(".cls") or filename.endswith(".flow-meta.xml"):

                    try:
                        result = run_analysis(file_path)

                        file_type = "APEX" if filename.endswith(".cls") else "FLOW"

                        file_results.append({
                            "file_name": filename,
                            "file_type": file_type,
                            "total_issues": len(result),
                            "violations": result
                        })

                        total_issues += len(result)

                        for v in result:
                            if v.get("severity") == "MAJOR":
                                major_count += 1
                            elif v.get("severity") == "MINOR":
                                minor_count += 1
                            elif v.get("severity") == "CRITICAL":
                                critical_count += 1



                    except Exception as e:
                        file_results.append({
                            "file_name": filename,
                            "file_type": "UNKNOWN",
                            "total_issues": 1,
                            "violations": [{
                                "rule": "FILE_ERROR",
                                "line": 0,
                                "severity": "CRITICAL",
                                "message": str(e)
                            }]
                        })
                        total_issues += 1
                        critical_count += 1


    finally:
        # Cleanup always runs
        if os.path.exists(extract_path):
            shutil.rmtree(extract_path)

        if os.path.exists(zip_path):
            os.remove(zip_path)

    return {
    "status": "success",
    "summary": {
        "total_files": len(file_results),
        "total_issues": total_issues,
        "major": major_count,
        "minor": minor_count,
        "critical": critical_count
    },
    "files": file_results
}

