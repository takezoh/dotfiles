from .core import CoreBuilder

import os

class EditorSupport(CoreBuilder):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def _map(self):
        if not '-game' in self.opts:
            return ''

        result = self.ctx.run(
            '''cd {}/Content && rg -g '*.umap' --files . 2>/dev/null | fzf -e --multi --no-sort --reverse --prompt='Choose map>'''.format(self.uproject.project_root),
            hide=False)

        selected = result.stdout.strip()
        if not selected:
            raise

        return '/Game/{}'.format(selected[2:-5])

    def launch(self, *args):
        cmdargs = [self.UNREAL_VERSION_SELECTOR, '/editor']

        editor = os.path.join(self.uproject.engine_root, 'Binaries/Win64/UE4Editor.exe')
        if os.path.exists(editor):
            cmdargs = [editor]

        cmdargs += [self.wpath(self.uproject.uproject_path), self._map()] + self.opts + ['-skipcompile', '-fullcrashdump']
        self.ctx.run(' '.join(cmdargs), echo=True)

