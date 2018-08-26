#!/usr/bin/env python
import sys
import json
import hashlib
import zipfile
import biplist
import axmlparserpy.apk


def main(path):
    info_cls = iOSInfo
    if path.endswith('.apk'):
        info_cls = AndroidInfo

    info = info_cls(path)
    hash = hashlib.md5(info.load_binary()).hexdigest()

    print json.dumps({
        'name': info.name,
        'version': info.version,
        'version_code': info.version_code,
        'hash': hash,
        })


class Info(dict):

    def __init__(self, path):
        super(Info, self).__init__()
        self.path = path

    def __getattr__(self, name):
        return self[name]

    def load_binary(self):
        return open(self.path, 'r').read()


class iOSInfo(Info):

    def __init__(self, path):
        super(iOSInfo, self).__init__(path)
        self._archive = zipfile.ZipFile(path, 'r')
        root = self._archive.namelist()[1]
        plist = biplist.readPlistFromString(self._archive.read(root + 'Info.plist'))
        self.update(
            name=plist['CFBundleIdentifier'],
            version=plist['CFBundleShortVersionString'],
            version_code=plist['CFBundleVersion'],
            executable_path=root + plist['CFBundleExecutable'],
            )

    def load_binary(self):
        return self._archive.read(self['executable_path'])


class AndroidInfo(Info):

    def __init__(self, path):
        super(AndroidInfo, self).__init__(path)
        package = axmlparserpy.apk.APK(path)
        self.update(
            name=package.package,
            version=package.androidversion_name,
            version_code=package.androidversion_code,
            )


if __name__ == '__main__':
    main(sys.argv[1])
