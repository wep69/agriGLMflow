#!/usr/bin/env python3
from pathlib import Path
import re, sys
ROOT=Path(__file__).resolve().parents[1]
errors=[]; warnings=[]

def lex_balance(path):
    s=path.read_text(encoding='utf-8')
    stack=[]; quote=None; esc=False; comment=False
    pairs={')':'(',']':'[','}':'{'}
    for i,ch in enumerate(s):
        if comment:
            if ch=='\n': comment=False
            continue
        if quote:
            if esc: esc=False; continue
            if ch=='\\': esc=True; continue
            if ch==quote: quote=None
            continue
        if ch=='#': comment=True; continue
        if ch in ('"',"'",'`'): quote=ch; continue
        if ch in '([{': stack.append((ch,i))
        elif ch in ')]}':
            if not stack or stack[-1][0]!=pairs[ch]:
                errors.append(f'{path.relative_to(ROOT)}: unmatched {ch} at {i}')
                return
            stack.pop()
    if quote: errors.append(f'{path.relative_to(ROOT)}: unterminated quote {quote}')
    if stack: errors.append(f'{path.relative_to(ROOT)}: unclosed delimiters {stack[-5:]}')

rfiles=list((ROOT/'R').glob('*.R'))+list((ROOT/'tests').rglob('*.R'))+list((ROOT/'data').glob('*.R'))+list((ROOT/'inst/simulation').glob('*.R'))
for f in rfiles: lex_balance(f)

# exports must be defined
ns=(ROOT/'NAMESPACE').read_text(encoding='utf-8')
exports=re.findall(r'^export\(([^)]+)\)',ns,re.M)
defs=set()
for f in (ROOT/'R').glob('*.R'):
    t=f.read_text(encoding='utf-8')
    defs.update(re.findall(r'(?m)^([A-Za-z.][A-Za-z0-9._]*)\s*<-\s*function\s*\(',t))
for x in exports:
    if x not in defs: errors.append(f'NAMESPACE exports undefined function: {x}')

# exported functions should have an Rd alias
aliases=set()
for f in (ROOT/'man').glob('*.Rd'):
    aliases.update(re.findall(r'\\alias\{([^}]+)\}',f.read_text(encoding='utf-8')))
for x in exports:
    if x not in aliases: errors.append(f'No Rd alias for exported function: {x}')

# each dataset script should be documented
for f in (ROOT/'data').glob('*.R'):
    if f.stem not in aliases: errors.append(f'No Rd alias for dataset: {f.stem}')

# Vignette metadata sanity
for f in (ROOT/'vignettes').glob('*.Rmd'):
    t=f.read_text(encoding='utf-8')
    if not t.startswith('---'): errors.append(f'{f.name}: missing YAML header')
    if '\\VignetteIndexEntry' not in t: errors.append(f'{f.name}: missing VignetteIndexEntry')

# State-of-the-art vignette and double-verified bibliography
state_vig=ROOT/'vignettes'/'v19-state-of-the-art.Rmd'
bib=ROOT/'vignettes'/'references.bib'
verif=ROOT/'inst'/'metadata'/'reference_verification.csv'
meta_md=ROOT/'inst'/'METADATA_VERIFICATION.md'
for req in (state_vig,bib,verif,meta_md):
    if not req.exists(): errors.append(f'Missing state-of-the-art metadata artifact: {req.relative_to(ROOT)}')
if bib.exists() and verif.exists():
    import csv
    bt=bib.read_text(encoding='utf-8')
    dois=set(re.findall(r'(?im)^\s*doi\s*=\s*\{([^}]+)\}',bt))
    with verif.open(encoding='utf-8',newline='') as fh:
        rows=list(csv.DictReader(fh))
    bydoi={r.get('doi','').strip():r for r in rows}
    for doi in sorted(dois):
        r=bydoi.get(doi)
        if not r:
            errors.append(f'No double-verification record for DOI: {doi}')
            continue
        sa=r.get('source_a','').strip(); sb=r.get('source_b','').strip()
        if not sa or not sb:
            errors.append(f'Incomplete double-verification sources for DOI: {doi}')
        elif sa.lower() == sb.lower():
            errors.append(f'Double-verification sources are not distinct for DOI: {doi}')
        if r.get('status','').strip().lower() != 'verified':
            errors.append(f'Reference DOI not marked verified: {doi}')
    # Every citation in the dedicated review must resolve to the bibliography.
    if state_vig.exists():
        cited=set(re.findall(r'@([A-Za-z0-9_:-]+)', state_vig.read_text(encoding='utf-8')))
        bibkeys=set(re.findall(r'@[A-Za-z]+\{([^,]+),', bt))
        for key in sorted(cited-bibkeys):
            errors.append(f'State-of-the-art vignette cites missing BibTeX key: {key}')
        # All bibliographic items used for this review should have a verification record.
        bykey={r.get('key','').strip():r for r in rows}
        for key in sorted(cited):
            if key not in bykey:
                errors.append(f'No metadata-verification record for cited key: {key}')

# DESCRIPTION safety
D=(ROOT/'DESCRIPTION').read_text(encoding='utf-8')
if 'github.com/agriGLMflow/agriGLMflow' in D: errors.append('DESCRIPTION contains unverified GitHub URL')
if 'maintainer@example.org' in D: errors.append('DESCRIPTION contains misleading maintainer placeholder')
if 'REPLACE_WITH_MAINTAINER_EMAIL@example.invalid' in D:
    warnings.append('DESCRIPTION still requires the real CRAN maintainer email before submission.')

# Old masked dataset name should not appear as a data() call
for f in ROOT.rglob('*'):
    if f.is_file() and f.suffix.lower() in {'.r','.rmd','.md','.rd'}:
        t=f.read_text(errors='ignore')
        if re.search(r'data\(agri_gamlss\)',t): errors.append(f'{f.relative_to(ROOT)}: old masked dataset agri_gamlss remains')

# Common temporary markers
for f in list((ROOT/'R').glob('*.R'))+list((ROOT/'man').glob('*.Rd')):
    t=f.read_text(errors='ignore')
    if re.search(r'\b(TODO|FIXME|XXX)\b',t): warnings.append(f'{f.relative_to(ROOT)} contains TODO/FIXME/XXX')

print(f'R-like files checked: {len(rfiles)}')
print(f'Exports checked: {len(exports)}')
print(f'Functions defined in R/: {len(defs)}')
print(f'Rd aliases: {len(aliases)}')
print(f'Datasets: {len(list((ROOT/"data").glob("*.R")))}')
print(f'Vignettes: {len(list((ROOT/"vignettes").glob("*.Rmd")))}')
if warnings:
    print('\nWARNINGS:')
    for w in warnings: print(' -',w)
if errors:
    print('\nERRORS:')
    for e in errors: print(' -',e)
    sys.exit(1)
print('\nSTATIC CHECK: PASS')
