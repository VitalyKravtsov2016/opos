# -*- coding: utf-8 -*-
import glob, os, sys, re

try:
    import pypdf
except ImportError:
    os.system(sys.executable + ' -m pip install pypdf -q')
    import pypdf

# Prefer programmer guide (larger file)
paths = sorted(glob.glob(r'd:\Projects\Shtrih\OposDriver\PosCenter\*.pdf'), key=lambda p: -os.path.getsize(p))
out_path = r'd:\Projects\Shtrih\opos\Test\SmFiscalPrinterTest\Bin\lic_extract2.txt'
pat = re.compile(
    r'лиценз|LicenseIsPresent|коммерческ|законодательн|бит\s*5[78]|FeatureLicens|'
    r'FMFlags|флаги\s*ФП|CommercialLicense|LegLicense|0x63|0x64|'
    r'mpCommercial|mpLeg|ReadFeatureLicenses|LicenseCommercial',
    re.I
)
with open(out_path, 'w', encoding='utf-8') as out:
    for path in paths[:1]:  # programmer guide first
        out.write('=== %s ===\n' % path)
        reader = pypdf.PdfReader(path)
        out.write('pages %d\n' % len(reader.pages))
        n = 0
        for i, page in enumerate(reader.pages):
            t = page.extract_text() or ''
            if not pat.search(t):
                continue
            # dump whole page text compressed
            out.write('\n===== PAGE %d =====\n' % (i + 1))
            out.write(t)
            out.write('\n')
            n += 1
            if n >= 30:
                break
        out.write('\nmatched pages %d\n' % n)
print('wrote', out_path)
