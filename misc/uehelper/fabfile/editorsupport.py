from .core import CoreBuilder

import os

class EditorSupport(CoreBuilder):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def launch(self, map, opts):
        # cmdargs = [self.wpath(self.UNREAL_VERSION_SELECTOR), '/editor']

        if not map and '-game' in opts:
            result = self.select_map()
            selected = result.stdout.strip()
            map = '/Game/{}'.format(selected[2:-5])

        #  editor = os.path.join(self.uproject.engine_root, 'Binaries/Win64/UE4Editor.exe')
        #  if os.path.exists(editor):
            #  cmdargs = [self.wpath(editor)]
        if os.path.exists(self.uproject.engine_root):
            cmdargs = [os.path.join(self.wpath(self.uproject.engine_root), 'Binaries/Win64/UE4Editor.exe')]

        cmdargs += [self.wpath(self.uproject.uproject_path), map, opts] + ['-skipcompile', '-fullcrashdump', '-NOVERIFYGC']
        self.ctx.run('cmd.exe /c start ' + ' '.join(cmdargs), echo=True)
