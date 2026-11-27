import hashlib
import json
import re
import subprocess
from pathlib import Path


def property_value(name):
    return subprocess.check_output(
        ["systemctl", "show", "chrony", f"--property={name}", "--value"], text=True
    ).strip()


pid = property_value("MainPID")
unit_path = property_value("FragmentPath")
print(
    json.dumps(
        {
            "arguments": Path(f"/proc/{pid}/cmdline").read_bytes().decode().strip("\0").split("\0"),
            "drift_paths": re.findall(
                r"(?m)^\s*driftfile\s+(\S+)", Path("/etc/chrony/chrony.conf").read_text()
            ),
            "drop_ins": property_value("DropInPaths"),
            "pid": pid,
            "unit_path": unit_path,
            "unit_sha256": hashlib.sha256(Path(unit_path).read_bytes()).hexdigest(),
        }
    )
)
