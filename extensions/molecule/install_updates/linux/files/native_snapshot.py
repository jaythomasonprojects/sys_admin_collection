import json
import subprocess
import sys
from pathlib import Path

import apt

cache = apt.Cache()
holds = subprocess.check_output(["apt-mark", "showhold"], text=True).splitlines()
eligible = [
    package.name
    for package in cache
    if package.is_installed
    and package.is_upgradable
    and package.candidate is not None
    and package.name not in holds
]
if len(sys.argv) > 1:
    name = sys.argv[1]
else:
    preferred = ["tzdata", "openssl", "ca-certificates", "curl"]
    name = next((name for name in preferred if name in eligible), None)
    if name is None and eligible:
        name = min(eligible)

package = cache[name] if name else None
print(
    json.dumps(
        {
            "boot_id": Path("/proc/sys/kernel/random/boot_id").read_text().strip(),
            "candidate": package.candidate.version if package and package.candidate else None,
            "held_version": cache["bash"].installed.version,
            "holds": holds,
            "installed": package.installed.version if package and package.installed else None,
            "package": name,
            "reboot_required": Path("/var/run/reboot-required").exists(),
            "upgradeable_count": len(eligible),
        }
    )
)
