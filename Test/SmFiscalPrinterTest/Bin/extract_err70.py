# -*- coding: utf-8 -*-
import glob, os, re
import pypdf

paths = sorted(glob.glob(r'd:\Projects\Shtrih\OposDriver\PosCenter\*.pdf'), key=lambda p: -os.path.getsize(p))
path = paths[0]  # programmer guide
reader = pypdf.PdfReader(path)
out = []
for i, page in enumerate(reader.pages):
    t = page.extract_text() or ''
    if re.search(r'(-70|не поддерживается драйвером|OpenCheck|открыть чек)', t, re.I):
        if 'OpenCheck' in t or '-70' in t or 'не поддерживается драйвером' in t:
            out.append('===== PAGE %d =====\n%s\n' % (i + 1, t))
open(r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\openchk.txt', 'w', encoding='utf-8').write('\n'.join(out[:40]))
print('chunks', len(out), 'written', min(40, len(out)))
