"""Check SDDM's layered theme settings without changing existing preferences."""
import configparser
from pathlib import Path
import sys

vendor, local, legacy, expected_dir = map(Path, sys.argv[1:])
config = configparser.ConfigParser(interpolation=None, strict=False)
config.optionxform = str
files = [*sorted(vendor.glob("*.conf")), *sorted(local.glob("*.conf")), legacy]
try:
    for path in files:
        if path.exists():
            with path.open(encoding="utf-8") as source:
                config.read_file(source, source=str(path))
except (configparser.Error, OSError) as error:
    sys.exit(f"Não foi possível verificar a configuração do SDDM: {error}")

current = config.get("Theme", "Current", fallback="").strip().strip('"')
directory = config.get("Theme", "ThemeDir", fallback="/usr/share/sddm/themes").strip().strip('"')
# expected_dir is passed explicitly so integration tests can isolate system paths.
if current != "rice-arch-astronaut" or Path(directory) != expected_dir:
    sys.exit(
        f"Conflito no SDDM: Current={current!r}, ThemeDir={directory!r}. "
        f"Confira {local} e {legacy}; o arquivo legado tem maior prioridade."
    )
print("Tema efetivo do SDDM: rice-arch-astronaut")
