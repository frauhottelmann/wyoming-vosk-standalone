#!/usr/bin/env python3
"""Docker healthcheck: ask the Wyoming server to describe itself."""
import json
import socket
import sys

HOST, PORT = "127.0.0.1", 10300

try:
    with socket.create_connection((HOST, PORT), timeout=3) as sock:
        sock.sendall(b'{"type": "describe"}\n')
        with sock.makefile("rb") as reader:
            header = json.loads(reader.readline())
except (OSError, ValueError) as err:
    print(f"unhealthy: {err}")
    sys.exit(1)

if header.get("type") != "info":
    print(f"unhealthy: unexpected event {header.get('type')!r}")
    sys.exit(1)
