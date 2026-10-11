"""Regenerate the complete symbol-name index from an installed SF Symbols app.

Usage: python3 Tools/build_catalog.py '/Applications/SF Symbols.app'
App-owned curated resources are maintained in the consuming app.
"""
import json
import plistlib
import re
import sys
from pathlib import Path

metadata = Path(sys.argv[1]) / 'Contents/Resources/Metadata'
def read(name):
    return plistlib.loads((metadata / (name + '.plist')).read_bytes())

aliases = {}
for filename in ['legacy_aliases.strings', 'name_aliases.strings']:
    aliases.update(re.findall(r'"([^"]+)"\s*=\s*"([^"]+)";', (metadata / filename).read_text()))
def canonical(name):
    seen = set()
    while name in aliases and name not in seen:
        seen.add(name)
        name = aliases[name]
    return name

reverse = {}
for alias in aliases:
    reverse.setdefault(canonical(alias), []).append(alias)
excluded = {'all', 'whatsnew', 'draw', 'variable', 'multicolor'}
categories = [c for c in read('categories') if c['key'] not in excluded]
keywords = read('symbol_search')
groups = read('symbol_categories')
names = read('name_availability')['symbols']
symbols = [{'name': name,
            'categories': groups.get(name, groups.get(canonical(name), [])),
            'keywords': keywords.get(name, keywords.get(canonical(name), [])),
            'aliases': sorted(set(reverse.get(canonical(name), []) + [canonical(name)]) - {name})}
           for name in sorted(names)]
output = Path(__file__).resolve().parents[1] / 'Sources/SwiftSymbolsIndex/Resources/catalog.json'
output.write_text(json.dumps({'categories': categories, 'symbols': symbols},
                            ensure_ascii=False, separators=(',', ':')))
