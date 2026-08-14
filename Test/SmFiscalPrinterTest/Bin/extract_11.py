# -*- coding: utf-8 -*-
import glob, os, re
import pypdf

paths = sorted(glob.glob(r'd:\Projects\Shtrih\OposDriver\PosCenter\*.pdf'), key=lambda p: os.path.getsize(p))
path = paths[0]  # protocol
reader = pypdf.PdfReader(path)
out = []
for i, page in enumerate(reader.pages):
    t = page.extract_text() or ''
    if re.search(r'(Код команды:\s*11h|команды:\s*11h|Get ECR|Запрос состояния ККТ)', t, re.I):
        out.append('===== PAGE %d =====\n%s\n' % (i + 1, t))
open(r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\cmd11.txt', 'w', encoding='utf-8').write('\n'.join(out))
print('chunks', len(out), 'file', path)
