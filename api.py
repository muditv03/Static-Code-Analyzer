from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import os
import zipfile
import shutil

from analyzer import analyze_project  # ✅ only use core analyzer

app = FastAPI()

UPLOAD_DIR = "uploads"
EXTRACT_DIR = "extracted"

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(EXTRACT_DIR, exist_ok=True)

# Allow CORS from frontend
origins = [
    "https://nucleus.mind-mesh.com",
    "https://test.mind-mesh.com",
    "http://localhost:3000"
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.post("/analyze-folder")
async def analyze_folder(file: UploadFile = File(...)):

    if not file.filename.endswith(".zip"):
        raise HTTPException(status_code=400, detail="Only ZIP files allowed")

    zip_path = os.path.join(UPLOAD_DIR, file.filename)

    # Save ZIP
    with open(zip_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    extract_path = os.path.join(
        EXTRACT_DIR, file.filename.replace(".zip", "")
    )

    if os.path.exists(extract_path):
        shutil.rmtree(extract_path)

    os.makedirs(extract_path, exist_ok=True)

    # Extract ZIP
    with zipfile.ZipFile(zip_path, "r") as zip_ref:
        for member in zip_ref.namelist():
            if not member.startswith("__MACOSX/"):
                zip_ref.extract(member, extract_path)

    try:
        # ✅ Single call to core analyzer
        file_results = analyze_project(extract_path)

        total_issues = 0
        major_count = 0
        minor_count = 0
        critical_count = 0

        for file in file_results:
            total_issues += file["total_issues"]

            for v in file["violations"]:
                severity = v.get("severity")
                if severity == "MAJOR":
                    major_count += 1
                elif severity == "MINOR":
                    minor_count += 1
                elif severity == "CRITICAL":
                    critical_count += 1

    finally:
        # Cleanup
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