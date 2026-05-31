import os
import sys
import json
import glob
import codecs
import shutil


class CoreBuilder():
    UNREAL_VERSION_SELECTOR = "/mnt/c/Program\\ Files\\ \\(x86\\)/Epic\\ Games/Launcher/Engine/Binaries/Win64/UnrealVersionSelector.exe"
    UNREAL_ENGINE_INSTALL_ROOT = '/mnt/c/Program\\ Files/Epic\\ Games'

    def __init__(self, ctx, *args, **kwargs):
        self.ctx = ctx

        current_dir = os.environ.get('TARGET_DIR')

        while current_dir != "/":
            results = glob.glob(current_dir + '/*.uproject')
            if not results:
                results = glob.glob(current_dir + '/*/*.uproject')
            for result in results:
                if not result.endswith('EngineTest.uproject'):
                    print ('Found {}'.format(result), file=sys.stderr)
                    self.uproject = UProject(result)
                    return

            current_dir = os.path.dirname(current_dir)

        raise HelperError("Not Found *.uproject")

    def select_map(self):
        return self.ctx.run(
            '''cd {}/Content && rg -g '*.umap' --files . 2>/dev/null | fzf -e --multi --no-sort --reverse --prompt='Choose map> ' '''.format(self.uproject.project_root),
            hide=False)

    @classmethod
    def _wslpath(cls, ctx, path, opt, escape=True):
        if not path:
            return ''

        r = ctx.run('wslpath {} \'{}\''.format(opt, path), hide=True).stdout.strip()

        if escape:
            return '"{}"'.format(r)
            return r.replace(' ', '\ ').replace('(', '\\(').replace(')', '\\)')
        return r

    def upath(self, wpath, escape=True):
        if wpath and wpath[-1] == '\\':
            wpath = wpath[0:-1]
        wpath = wpath.replace('\\', '\\\\')
        return self._wslpath(self.ctx, wpath, '-au', escape)

    def wpath(self, upath, escape=True):
        return self._wslpath(self.ctx, upath, '-am', escape)


class HelperError(ValueError): pass


class UProject():
    def __init__(self, uproject_path):
        context = json.load(codecs.open(uproject_path, 'r', 'utf-8-sig'))

        self.file_version = context["FileVersion"]
        self.engine_association = context["EngineAssociation"]
        self.modules = context.get('Modules')
        self.has_modules = bool(self.modules)

        self.uproject_path = uproject_path
        self.name = os.path.basename(uproject_path)[:-len('.uproject')]
        self.project_root = os.path.dirname(uproject_path)

        self.root_path = os.path.dirname(self.project_root)

        editor_path_file = glob.glob(self.root_path + '/.ue4-version') \
                        or glob.glob(self.root_path + '/*/.ue4-version')
        if editor_path_file:
            self.root_path = os.path.dirname(editor_path_file[0])
            with open(editor_path_file[0], 'r') as f:
                self.engine_root = f.read().strip()
        else:
            engine_path = glob.glob(self.root_path + '/Engine/Build/Build.version') \
                       or glob.glob(self.root_path + '/*/Engine/Build/Build.version')
            print(engine_path)
            self.engine_root = os.path.dirname(os.path.dirname(engine_path[0]))

        if not os.path.exists(self.engine_root):
            self.root_path = self.project_root
            self.engine_root = os.path.join(CoreBuilder.UNREAL_ENGINE_INSTALL_ROOT, 'UE_' + self.engine_association, 'Engine')
