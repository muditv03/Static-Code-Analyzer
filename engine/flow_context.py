import xml.etree.ElementTree as ET
from utils.file_loader import load_file


class FlowContext:
    def __init__(self, file_path):
        self.file_path = file_path

        # ---- Safe raw text loading ----
        self.code = load_file(file_path)
        self.lines = self.code.split("\n")

        # ---- XML parsing ----
        try:
            self.tree = ET.ElementTree(ET.fromstring(self.code))
            self.root = self.tree.getroot()
            self.namespace = {
                "sf": self.root.tag.split("}")[0].strip("{")
            }
        except ET.ParseError as e:
            raise Exception(f"Invalid XML structure: {str(e)}")
