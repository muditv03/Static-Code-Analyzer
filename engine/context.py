class AnalysisContext:
    def __init__(self, code):
        self.code = code
        self.lines = code.split("\n")
