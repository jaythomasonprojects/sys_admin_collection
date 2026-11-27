"""Compute a literal startup assignment without evaluating shell code."""

import json
import re
import shlex
import stat
import sys
from pathlib import Path

path = Path(sys.argv[1])
enabled = sys.argv[2] == "true"
text = path.read_text() if path.exists() else ""
assignments = re.findall(r"(?m)^([ \t]*DAEMON_OPTS=)(.*)$", text)
line = None
if assignments:
    prefix, raw = assignments[-1]
    lexer = shlex.shlex(raw, posix=True)
    lexer.whitespace_split = True
    lexer.commenters = ""
    options = lexer.get_token()
    trailing = lexer.instream.read()
    if options is None or (trailing.strip() and not trailing.lstrip().startswith("#")):
        raise ValueError("DAEMON_OPTS must be a literal packaged option assignment")
    updated = options
    option = re.compile(r"(?<!\S)-s(?=\s|$)")
    if enabled:
        if not option.search(options):
            updated += (" " if options and not options[-1].isspace() else "") + "-s"
    else:
        updated = option.sub("", options)
    line = prefix + raw
    if updated != options:
        escaped = updated.replace("\\", "\\\\").replace('"', '\\"')
        escaped = escaped.replace("$", "\\$").replace("`", "\\`")
        comment = " " + trailing.lstrip() if trailing.strip() else ""
        line = f'{prefix}"{escaped}"{comment}'
elif enabled:
    line = 'DAEMON_OPTS="-s"'

mode = f"{stat.S_IMODE(path.stat().st_mode):04o}" if path.exists() else "0644"
print(json.dumps({"line": line, "mode": mode}))
