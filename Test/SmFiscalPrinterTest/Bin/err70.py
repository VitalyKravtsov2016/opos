# -*- coding: utf-8 -*-
import re
p = r'C:\Program Files (x86)\PosCenter\DrvKKT\Bin\DrvFR.dll'
d = open(p, 'rb').read()
out = []
for needle in ['драйвером', 'не поддерживается', 'поддерживается драйвером', 'E_MODEL', 'not supported']:
    b = needle.encode('utf-16le')
    idx = 0
    n = 0
    while n < 5:
        idx = d.find(b, idx)
        if idx < 0:
            break
        # expand to full utf16 string
        start = idx
        while start >= 2 and d[start - 1] != 0:
            # previous char high byte should be 0 for BMP
            start -= 2
            if start < 0:
                start = 0
                break
        # actually scan backward while looking like utf16 chars
        start = idx
        while start >= 2:
            lo, hi = d[start - 2], d[start - 1]
            if hi == 0 and 32 <= lo < 255:
                start -= 2
            elif hi == 0 and lo == 0:
                break
            else:
                # allow cyrillic hi != 0
                if lo == 0 and hi == 0:
                    break
                start -= 2
                if idx - start > 200:
                    break
        end = idx
        while end + 2 <= len(d):
            lo, hi = d[end], d[end + 1]
            if lo == 0 and hi == 0:
                break
            end += 2
            if end - start > 300:
                break
        try:
            s = d[start:end].decode('utf-16le')
        except Exception:
            s = repr(d[start:end])
        out.append('[%s @%d] %s' % (needle, idx, s))
        idx = end
        n += 1

open(r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\err70.txt', 'w', encoding='utf-8').write('\n'.join(out))
print('lines', len(out))
