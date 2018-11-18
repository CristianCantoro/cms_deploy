#!/usr/bin/env python3

import sys
import json
import urllib.request


# globals
CMSGH_API_RELEASES = "https://api.github.com/repos/cms-dev/cms/releases"


# error codes
ENOTENOUGHARGS = 2
ENORELEASE = 1


if __name__ == '__main__':

    if len(sys.argv) < 2:
        print("Error. Not enough arguments.", file=sys.stderr)
        print("  Usage: check_cms_release.py <release>", file=sys.stderr)
        exit(ENOTENOUGHARGS)

    target = sys.argv[1]

    contents = (urllib.request
                      .urlopen(CMSGH_API_RELEASES)
                      .read()
                )
    res = json.loads(contents)

    releases = [release['tag_name'] for release in res]
    
    if target in releases:
        exit(0)
    else:
        print("Error. Target release '{}' not found".format(target),
              file=sys.stderr)
        exit(ENORELEASE)