import os
import sys
import json
import glob
import shutil


class CoreBuilder():
    UNREAL_VERSION_SELECTOR = "/mnt/c/Program\\ Files\\ \\(x86\\)/Epic\\ Games/Launcher/Engine/Binaries/Win64/UnrealVersionSelector.exe"
    UNREAL_ENGINE_INSTALL_ROOT = '/mnt/c/Program\\ Files/Epic\\ Games'

    def __init__(self, ctx, *args, **kwargs):
        self.ctx = ctx
        self.opts = [x.strip() for x in (kwargs.get('opts') or '').split(' ')]
        self.env = {
            'PATH': '{}/bin:/usr/bin:/bin'.format(os.path.dirname(__file__)),
            }

        current_dir = os.environ.get('TARGET_DIR')

        while current_dir != "/":
            result = glob.glob(current_dir + '/*.uproject')
            if not result:
                result = glob.glob(current_dir + '/*/*.uproject')
            if result:
                print ('Found {}'.format(result[0]), file=sys.stderr)
                self.uproject = UProject(result[0])
                return

            current_dir = os.path.dirname(current_dir)

        raise HelperError("Not Found *.uproject")

    @classmethod
    def _wslpath(cls, ctx, path, opt):
        if not path:
            return ''
        def escape(path):
            path = path.replace('Unreal Projects', 'Unreal\\ Projects')
            path = path.replace('Epic Games', 'Epic\\ Games')
            path = path.replace('Program Files (x86)', 'Program\\ Files\\ \\(x86\\)')
            path = path.replace('Program Files', 'Program\\ Files')
            return path
        return escape(ctx.run('wslpath {} {}'.format(opt, escape(path)), hide=True).stdout.strip())

    def upath(self, wpath):
        if wpath and wpath[-1] == '\\':
            wpath = wpath[0:-1]
        wpath = wpath.replace('\\', '\\\\')
        return self._wslpath(self.ctx, wpath, '-au')

    def wpath(self, upath):
        return self._wslpath(self.ctx, upath, '-am')


class HelperError(ValueError): pass


class UProject():
    def __init__(self, uproject_path):
        context = json.load(open(uproject_path, 'r'))

        self.file_version = context["FileVersion"]
        self.engine_association = context["EngineAssociation"]

        self.uproject_path = uproject_path
        self.name = os.path.basename(uproject_path)[:-len('.uproject')]
        self.project_root = os.path.dirname(uproject_path)

        self.root_path = os.path.dirname(self.project_root)
        self.engine_root = os.path.join(self.root_path, 'Engine')
        if not os.path.exists(self.engine_root):
            self.root_path = self.project_root
            self.engine_root = os.path.join(CoreBuilder.UNREAL_ENGINE_INSTALL_ROOT, 'UE_' + self.engine_association, 'Engine')
