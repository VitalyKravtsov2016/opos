# -*- coding: utf-8 -*-
import glob, os, sys

try:
    import pypdf
except ImportError:
    os.system(sys.executable + ' -m pip install pypdf -q')
    import pypdf

paths = glob.glob(r'd:\Projects\Shtrih\OposDriver\PosCenter\*.pdf')
keywords = [
    'LicenseIsPresent', 'LicenseCommercial', 'коммерческ', 'законодатель',
    'бит 57', 'бит 58', 'FMFlags', 'флаги ФП', 'mpCommercial', '0x63',
    'ReadFeatureLicenses', 'LicenseEntered', 'лиценз', 'бит 2',
    'CommercialLicense', 'LegLicense'
]
out_path = r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\lic_extract.txt'
with open(out_path, 'w', encoding='utf-8') as out:
    for path in paths:
        out.write('=== %s ===\n' % path)
        try:
            reader = pypdf.PdfReader(path)
        except Exception as e:
            out.write('open err %s\n' % e)
            continue
        out.write('pages %d\n' % len(reader.pages))
        count = 0
        for i, page in enumerate(reader.pages):
            try:
                t = page.extract_text() or ''
            except Exception:
                continue
            matched = False
            for kw in keywords:
                if kw.lower() in t.lower():
                    matched = True
                    break
            if not matched:
                continue
            lines = t.splitlines()
            for j, line in enumerate(lines):
                for kw in keywords:
                    if kw.lower() in line.lower():
                        ctx = '\n'.join(lines[max(0, j - 2):min(len(lines), j + 5)])
                        out.write('--- p%d [%s] ---\n%s\n\n' % (i + 1, kw, ctx[:800]))
                        count += 1
                        break
            if count > 80:
                break
        out.write('total hits %d\n\n' % count)
print('wrote', out_path)
