#!/usr/bin/env python3

import sys

from pathlib import Path
path = Path(str(Path(__file__).resolve()) + '/../../lib').resolve()
sys.path.append(str(path))

from grobidconverter import GrobidConverter

if len(sys.argv) < 2:
    print("Usage: ./grobid2json.py file.pdf")
    sys.exit(1)

pdf_path = sys.argv[1]

gc = GrobidConverter()
gc.convert_pdf_to_json(pdf_path)
