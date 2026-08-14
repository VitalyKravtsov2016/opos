# -*- coding: utf-8 -*-
import glob, os, re
import pypdf

paths = sorted(glob.glob(r'd:\Projects\Shtrih\OposDriver\PosCenter\*.pdf'), key=lambda p: os.path.getsize(p))
path = paths[0]
reader = pypdf.PdfReader(path)
out = []
for i, page in enumerate(reader.pages):
    t = page.extract_text() or ''
    if re.search(r'(FE\s*E7|FEE7|E7h|функциональн\w*\s+лиценз|цифровой подписи)', t, re.I):
        out.append('===== PAGE %d =====\n%s\n' % (i + 1, t))
open(r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\fee7.txt', 'w', encoding='utf-8').write('\n'.join(out))
print('chunks', len(out))
