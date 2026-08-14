# -*- coding: utf-8 -*-
import re
p = r'C:\Program Files (x86)\PosCenter\DrvKKT\Bin\DrvFR.dll'
data = open(p, 'rb').read()
needles = [
    'устройств', 'лиценз', 'коммерч', 'не поддер', 'OpenCheck',
    'HasLicense', 'CheckLicense', 'E_NOLICENSE', 'ERR_', 'бит 57',
    'Commercial', 'CashCore', 'CashControl'
]
found = []
for m in re.finditer(rb'(?:[\x20-\xff]\x00){6,}', data):
    try:
        s = m.group().decode('utf-16le')
    except Exception:
        continue
    sl = s.lower()
    if any(n.lower() in sl for n in needles):
        found.append(s.replace('\r', ' ').replace('\n', ' ')[:300])
for m in re.finditer(rb'[\x20-\x7e]{8,160}', data):
    s = m.group().decode('ascii')
    if any(n.lower() in s.lower() for n in needles):
        found.append(s)
out = r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\dll_strings.txt'
with open(out, 'w', encoding='utf-8') as f:
    for s in sorted(set(found)):
        f.write(s + '\n')
    f.write('TOTAL %d\n' % len(set(found)))
print('wrote', out, 'count', len(set(found)))
