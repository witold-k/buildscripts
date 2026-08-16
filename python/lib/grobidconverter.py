import requests
import json
import re
from lxml import etree


class GrobidConverter:
    """
    High-level converter:
    PDF → TEI → Clean TEI → JSON (LLM-optimized)
    """

    NS = {"tei": "http://www.tei-c.org/ns/1.0"}

    REMOVE_TAGS = [
        "tagsDecl",
        "encodingDesc",
        "revisionDesc",
        "profileDesc",
        "facsimile",
    ]

    REMOVE_PATTERNS = [
        r"<desc>GROBID[^<]*</desc>",
    ]

    def __init__(self, grobid_url="http://localhost:8070/api/processFulltextDocument"):
        self.grobid_url = grobid_url

    # ---------------------------------------------------------
    # 1. PDF → TEI
    # ---------------------------------------------------------
    def extract_tei(self, pdf_path):
        with open(pdf_path, "rb") as f:
            files = {"input": f}
            data = {
                "consolidateHeader": "1",
                "teiCoordinates": "true",
                "generateIDs": "true",
                "segmentSentences": "true"
            }
            print("➡️  Sending PDF to GROBID…")
            r = requests.post(self.grobid_url, files=files, data=data)
            r.raise_for_status()
            return r.text

    # ---------------------------------------------------------
    # 2. TEI Cleaning
    # ---------------------------------------------------------
    def clean_tei(self, xml_text):
        print("🧹 Cleaning TEI…")

        # remove known junk patterns
        for pat in self.REMOVE_PATTERNS:
            xml_text = re.sub(pat, "", xml_text, flags=re.MULTILINE)

        parser = etree.XMLParser(remove_comments=True)
        root = etree.fromstring(xml_text.encode("utf-8"), parser)

        # remove unwanted tags
        for tag in self.REMOVE_TAGS:
            for elem in root.findall(f".//{{http://www.tei-c.org/ns/1.0}}{tag}"):
                elem.getparent().remove(elem)

        return root

    # ---------------------------------------------------------
    # Helper: extract text
    # ---------------------------------------------------------
    def _text(self, elem):
        if elem is None:
            return ""
        return " ".join(" ".join(elem.itertext()).split())

    # ---------------------------------------------------------
    # 3. TEI → JSON (LLM-optimized)
    # ---------------------------------------------------------
    def tei_to_json(self, root):
        print("🔄 Converting TEI → JSON…")

        # Title
        title = self._text(root.find(".//tei:titleStmt/tei:title", self.NS))

        # Authors
        authors = [
            self._text(a)
            for a in root.findall(".//tei:author", self.NS)
        ]

        # Abstract
        abstract = self._text(root.find(".//tei:abstract", self.NS))

        # Sections
        sections = []
        for div in root.findall(".//tei:body//tei:div", self.NS):
            heading = self._text(div.find("tei:head", self.NS))
            paragraphs = [
                self._text(p) for p in div.findall("tei:p", self.NS)
            ]
            sections.append({
                "heading": heading,
                "text": "\n".join(paragraphs)
            })

        # References
        references = []
        for bibl in root.findall(".//tei:listBibl/tei:biblStruct", self.NS):
            ref_id = bibl.get("{http://www.w3.org/XML/1998/namespace}id")
            references.append({
                "id": ref_id,
                "text": self._text(bibl)
            })

        return {
            "title": title,
            "authors": authors,
            "abstract": abstract,
            "sections": sections,
            "references": references
        }

    # ---------------------------------------------------------
    # High-level pipeline
    # ---------------------------------------------------------
    def convert_pdf_to_json(self, pdf_path, json_path=None):
        base = pdf_path.rsplit(".", 1)[0]

        # 1. Extract TEI
        tei_raw = self.extract_tei(pdf_path)

        # 2. Clean TEI
        root = self.clean_tei(tei_raw)

        # 3. Convert to JSON
        data = self.tei_to_json(root)

        # Save JSON
        if json_path is None:
            json_path = base + ".json"

        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)

        print(f"✨ JSON saved to: {json_path}")
        return data

