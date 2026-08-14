# -*- coding: utf-8 -*-
import glob, os, re
import pypdf

# Protocol PDF (smaller) - find footnote [8] near F7
paths = sorted(glob.glob(r'd:\Projects\Shtrih\OposDriver\PosCenter\*.pdf'), key=lambda p: os.path.getsize(p))
path = paths[0]
reader = pypdf.PdfReader(path)
out = []
for i, page in enumerate(reader.pages):
    t = page.extract_text() or ''
    if 'бит 57' in t.lower() or 'Бит 57' in t or '[8]' in t and 'лиценз' in t.lower():
        out.append('===== PAGE %d =====\n%s\n' % (i + 1, t))
    elif re.search(r'Примечан[\s\S]{0,200}\[8\]', t) and 'F7' in t:
        out.append('===== PAGE %d =====\n%s\n' % (i + 1, t))

# also pages around 41
for i in (39, 40, 41, 42):
    if 0 <= i < len(reader.pages):
        out.append('===== FORCE PAGE %d =====\n%s\n' % (i + 1, reader.pages[i].extract_text() or ''))

open(r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\note8.txt', 'w', encoding='utf-8').write('\n'.join(out))
print('pages', len(reader.pages), 'chunks', len(out))
