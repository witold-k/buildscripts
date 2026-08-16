#!/usr/bin/python3

import sys

from pathlib import Path
path = Path(str(Path(__file__).resolve()) + '/../../lib/ai').resolve()
sys.path.append(str(path))

from airequest import AIRequest

air = AIRequest("")
print(air.request(sys.argv[1]))

