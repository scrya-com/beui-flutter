#!/usr/bin/env python3
"""Serve an unzipped beui-gallery CI artifact so Flutter's <base href> resolves.

Run this from the folder that contains this script (the artifact root), not
from the nested app directory. The gallery is at /<repo-name>/.
"""

from __future__ import annotations

import http.server
import os
import sys
from functools import partial

PORT = int(os.environ.get("PORT", "8080"))


def main() -> int:
    root = os.path.dirname(os.path.abspath(__file__))
    os.chdir(root)
    apps = [
        name
        for name in sorted(os.listdir(root))
        if os.path.isdir(name)
        and os.path.isfile(os.path.join(name, "index.html"))
    ]
    handler = partial(http.server.SimpleHTTPRequestHandler, directory=root)
    server = http.server.ThreadingHTTPServer(("127.0.0.1", PORT), handler)
    print("beUI gallery")
    if apps:
        for name in apps:
            print(f"  http://127.0.0.1:{PORT}/{name}/")
    else:
        print(f"  http://127.0.0.1:{PORT}/")
    print("Ctrl-C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
