"""Fingerprint the complete production snapshot or one separately built product."""
import hashlib
from pathlib import Path


def production_digest(root: Path, module: str | None = None) -> str:
    directory = root / 'Sources'
    if module is not None:
        directory /= module
    digest = hashlib.sha256()
    for source in sorted(directory.rglob('*.swift')):
        digest.update(str(source.relative_to(root)).encode())
        digest.update(source.read_bytes())
    return digest.hexdigest()
