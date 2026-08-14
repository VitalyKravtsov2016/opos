# -*- coding: utf-8 -*-
import glob, os
import pypdf

paths = sorted(glob.glob(r'd:\Projects\Shtrih\OposDriver\PosCenter\*.pdf'), key=lambda p: os.path.getsize(p))
path = paths[0]
reader = pypdf.PdfReader(path)
# pages 18-21 are 0-indexed 17-20
chunks = []
for i in range(17, 22):
    chunks.append('===== PAGE %d =====\n%s\n' % (i + 1, reader.pages[i].extract_text() or ''))
open(r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\cmd11b.txt', 'w', encoding='utf-8').write('\n'.join(chunks))
print('ok')
