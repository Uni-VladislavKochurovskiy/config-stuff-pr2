import functools
import http.server
import pathlib
import sys

handler = functools.partial(
    http.server.SimpleHTTPRequestHandler, directory="tests/fixtures"
)
with http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler) as server:
    pathlib.Path(sys.argv[1]).write_text(str(server.server_port))
    server.serve_forever()
