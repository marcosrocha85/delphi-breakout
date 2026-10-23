"""Generate the public API with a pinned PasDoc version (Python stdlib only)."""

import argparse
from pathlib import Path
import re
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--pasdoc', default='pasdoc', help='PasDoc executable or command on PATH')
    parser.add_argument('--output', default='docs/api', help='Output path relative to the repository')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[2]
    executable = str(Path(args.pasdoc).resolve()) if Path(args.pasdoc).is_file() else args.pasdoc
    version = subprocess.run([executable, '--version'], capture_output=True, text=True,
                             encoding='utf-8', errors='replace', check=True)
    if not re.search(r'PasDoc 1\.0\.4(?:\s|$)', version.stdout):
        parser.error('Use PasDoc 1.0.4 to reproduce the checked-in HTML')
    output = root / args.output
    output.mkdir(parents=True, exist_ok=True)
    sources = ['Types', 'Game', 'Loop', 'Physics', 'Bricks', 'Levels',
               'Presentation', 'Renderer.Vcl', 'Texts']
    result = subprocess.run(
        [executable, '@tools/docs/pasdoc.options', '--output', str(output)] +
        [f'src/Breakout.{name}.pas' for name in sources], cwd=root,
        capture_output=True, text=True, encoding='utf-8', errors='replace')
    messages = result.stdout + result.stderr
    print(messages, end='')
    if result.returncode or re.search(r'\b(?:warning|error)\[', messages, re.IGNORECASE):
        raise SystemExit('PasDoc reported an error or warning; review before committing')
    # PasDoc emits a space-only line on introduction pages. Keep generated
    # HTML free of trailing whitespace without altering its line endings.
    for page in output.glob('*.html'):
        page.write_bytes(re.sub(rb'[ \t]+(?=\r?$)', b'', page.read_bytes(), flags=re.MULTILINE))
    print(f'API generated: {output / "index.html"}')


if __name__ == '__main__':
    main()
