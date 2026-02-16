import xml.etree.ElementTree as ET

class FlowContext:
    def __init__(self, file_path):
        self.file_path = file_path
        self.tree = ET.parse(file_path)
        self.root = self.tree.getroot()

        self.namespace = {
            "sf": self.root.tag.split("}")[0].strip("{")
        }
