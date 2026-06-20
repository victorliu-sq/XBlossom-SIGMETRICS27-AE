import sys

from onedrivedownloader import download


def main() -> int:
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <onedrive-link> <output-tarball>", file=sys.stderr)
        return 2

    link = sys.argv[1]
    out = sys.argv[2]
    download(link, filename=out, unzip=False, force_download=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
