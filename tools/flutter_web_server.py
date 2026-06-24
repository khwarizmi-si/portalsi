from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import argparse
import os


class FlutterWebHandler(SimpleHTTPRequestHandler):
    def do_GET(self):
        requested = Path(self.translate_path(self.path))
        if not requested.exists() and "." not in Path(self.path).name:
            self.path = "/index.html"
        super().do_GET()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", default=3000, type=int)
    parser.add_argument("--dir", default="build/web")
    args = parser.parse_args()

    os.chdir(args.dir)
    server = ThreadingHTTPServer((args.host, args.port), FlutterWebHandler)
    print(f"Serving Flutter web at http://{args.host}:{args.port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
