# -*- coding: utf-8 -*-
import glob, os, re
import pypdf

paths = sorted(glob.glob(r'd:\Projects\Shtrih\OposDriver\PosCenter\*.pdf'), key=lambda p: -os.path.getsize(p))
path = paths[0]
reader = pypdf.PdfReader(path)
# TOC said OpenCheck around page 83; PDF page index ~82
chunks = []
for i in range(80, 95):
    if i < len(reader.pages):
        t = reader.pages[i].extract_text() or ''
        if 'OpenCheck' in t or 'открыть чек' in t.lower() or '-70' in t:
            chunks.append('===== PAGE %d =====\n%s\n' % (i + 1, t))
# also search error codes section
for i, page in enumerate(reader.pages):
    t = page.extract_text() or ''
    if re.search(r'код ошибки\s*-70|-70\s|E_\w*70|не поддерживается драйвером', t, re.I):
        chunks.append('===== HIT PAGE %d =====\n%s\n' % (i + 1, t))
open(r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\open_doc.txt', 'w', encoding='utf-8').write('\n'.join(chunks[:20]))
print('chunks', len(chunks))
