#!/usr/bin/env python
import sys
import argparse
import plistlib
import lxml.etree


def update_info(path, info):
    if path.endswith('.plist'):
        plist = plistlib.readPlist(path)
        plist.update(info)
        plistlib.writePlist(plist, path)

    elif path.endswith('.xml'):
        tree = lxml.etree.parse(path)
        root = tree.getroot()
        for k, v in info.items():
            root.set(k, v)
        tree.write(open(path, 'w'), encoding='utf-8', xml_declaration=True)


def convert_map(platform, info):
    name_map = {}
    if platform == 'ios':
        name_map = {
            'name': 'CFBundleIdentifier',
            'version': 'CFBundleShortVersionString',
            'version_code': 'CFBundleVersion',
        }

    elif platform == 'android':
        ns = "{http://schemas.android.com/apk/res/android}"
        name_map = {
            'name': 'package',
            'version': ns + 'versionName',
            'version_code': ns + 'versionCode',
        }

    return {name_map[k]: v for k, v in info.items() if v}


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--name', dest='name')
    parser.add_argument('--version', dest='version')
    parser.add_argument('--code', dest='version_code')
    args = parser.parse_args(sys.argv[3:])

    platform = sys.argv[1]
    path = sys.argv[2]

    print args.__dict__
    update_info(path, convert_map(platform, args.__dict__))
