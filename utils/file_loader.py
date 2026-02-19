def load_file(path):
    with open(path, "rb") as f:
        raw = f.read()

    try:
        return raw.decode("utf-8")
    except UnicodeDecodeError:
        return raw.decode("latin-1", errors="ignore")
