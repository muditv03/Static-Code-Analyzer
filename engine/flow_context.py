import xml.etree.ElementTree as ET

class FlowContext:
    def __init__(self, file_path):
        self.file_path = file_path

        # ---- raw text (for regex + line numbers) ----
        with open(file_path, "r", encoding="utf-8") as f:
            self.code = f.read()
            self.lines = self.code.split("\n")

        # ---- XML parsing (for structure-based rules) ----
        self.tree = ET.ElementTree(ET.fromstring(self.code))
        self.root = self.tree.getroot()

        self.namespace = {
            "sf": self.root.tag.split("}")[0].strip("{")
        }
