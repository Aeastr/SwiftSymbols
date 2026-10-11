"""Extract name/category/search metadata from an installed SF Symbols app.

Usage: python3 Tools/build_catalog.py '/Applications/SF Symbols.app'
No symbol artwork or font files are copied.
"""
import json
import plistlib
import sys
from pathlib import Path

metadata = Path(sys.argv[1]) / 'Contents/Resources/Metadata'
def read(name):
    return plistlib.loads((metadata / (name + '.plist')).read_bytes())

excluded = {'all', 'whatsnew', 'draw', 'variable', 'multicolor'}
categories = [c for c in read('categories') if c['key'] not in excluded]
keywords = read('symbol_search')
symbols = [{'name': name, 'categories': groups, 'keywords': keywords.get(name, [])}
           for name, groups in sorted(read('symbol_categories').items())]
output = Path(__file__).resolve().parents[1] / 'Sources/SwiftSymbolsIndex/Resources/catalog.json'
output.write_text(json.dumps({'categories': categories, 'symbols': symbols},
                            ensure_ascii=False, separators=(',', ':')))
