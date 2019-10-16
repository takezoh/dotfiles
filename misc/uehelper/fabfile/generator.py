from .core import CoreBuilder
from .build import BuildCommand

import os
import json


class ProjectGenerator(CoreBuilder):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

    def project_files(self, *args, **kwargs):
        cmdargs = [self.UNREAL_VERSION_SELECTOR, '/projectfiles']

        builder = os.path.join(self.uproject.engine_root, 'Build/BatchFiles/GenerateProjectFiles.bat')
        if os.path.exists(builder):
            cmdargs = ['/mnt/c/Windows/System32/cmd.exe', '/c', self.wpath(builder)]

        cmd = ' '.join(cmdargs + [self.wpath(self.uproject.uproject_path), '-Game', '-Engine', '-makefile', '-2017', '-VSCode'] + list(args))
        self.ctx.run(cmd, echo=True)

    def manifest_file(self, *args, **kwargs):
        target = self.uproject.name + 'Editor'
        platform = 'Win64'
        configuration = 'Development'
        uproject_path = self.wpath(self.uproject.uproject_path)

        cmdargs = [
            self.wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/Build.bat')),
            target,
            platform,
            configuration,
            '-Project={}'.format(uproject_path),
            uproject_path,
            '-generatemanifest',
            '-Game', '-Engine', '-2017',
            #  '-WaitMutex', '-FromMsBuild', 
            ]
            #  '-NoUBTMakefiles', '-remoteini={}'.format(self.wpath(self.uproject.root_path)),
            #  '-skipdeploy', '-noxge', '-generatemanifest', '-NoHotReload']

        self.ctx.run('/mnt/c/Windows/System32/cmd.exe /c ' + ' '.join(cmdargs), echo=True)

    def support_files(self, *args, **kwargs):
        manifest = UhtManifest(self, self.uproject)

        self._configure(manifest)
        self._patch_vscode_project(manifest)
        self._gen_compilation_databases(manifest)

    def _configure(self, manifest):
        # fetch include directories
        include_dirs = []
        source_directory = ''
        for m in manifest.modules:
            #  ii = subp_output(['find', m.include_base, '-type', 'd']).strip()
            ii = self.ctx.run(' '.join(['find', m.include_base, '-type', 'd']), hide=True).stdout.strip()
            include_dirs[len(include_dirs):] = ii.split('\n')
            include_dirs.append(m.output_directory)
            if m.name == self.uproject.name:
                source_directory = self.upath(m.base_directory)

        # copy files
        for frm, to, rep in [
                ('ignore', '.ignore', {}),
                ('project.gtags.conf', os.path.join('.uproject', 'gtags.game', 'gtags.conf'), {}),
                ('engine.gtags.conf', os.path.join('.uproject', 'gtags.engine', 'gtags.conf'), {}),
                ('globalrc.template', '.globalrc', {
                        'project_root': self.uproject.project_root,
                        'engine_root': self.uproject.engine_root,
                        'gtagsdb_root': os.path.join(self.uproject.root_path, '.uproject'),
                    }),
                ('globalrc.template.bat', 'globalrc.bat', {
                        'project_root': self.wpath(self.uproject.project_root),
                        'engine_root': self.wpath(self.uproject.engine_root),
                        'gtagsdb_root': self.wpath(os.path.join(self.uproject.root_path, '.uproject')),
                    }),
                #  ('clang.template', '.clang', {
                        #  'compilation_database': os.path.join(self.uproject.root_path, '.uproject', 'cmake.build'),
                    #  }),
                ('clang.flags.template', '.clang', {
                        'flags': '-x c++ -std=c++14 ' + ' '.join(['-I{}'.format(x) for x in include_dirs]),
                    }),
                #  ('CMakeLists.template.txt', os.path.join('.uproject', 'CMakeLists.txt'), {
                        #  'include_directories': ' '.join(['"{}"'.format(x) for x in include_dirs]),
                        #  'source_directory': source_directory,
                    #  }),
                ]:
            to = os.path.join(self.uproject.root_path, to)
            frm = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', frm)
            try:
                if not os.path.exists(os.path.dirname(to)):
                    os.makedirs(os.path.dirname(to))
                open(to, 'w').write(
                    open(frm, 'r').read().format(**rep))
            except Exception as e:
                print (e, file=sys.stderr)

    def _patch_vscode_project(self, manifest):
        # VSCode UE4.code-workspace
        vscode_project = os.path.join(self.uproject.project_root, 'UE4.code-workspace')
        if not os.path.exists(vscode_project):
            return
        context = json.load(open(vscode_project, 'r'))
        context["settings"]["codegnuglobal.executable"] = "globalrc.bat"
        context["settings"]["codegnuglobal.autoupdate"] = True
        json.dump(context, open(vscode_project, 'w'), indent=4)

        try:
            os.makedirs(os.path.join(self.uproject.root_path, '.vscode'))
        except OSError:
            pass

        # VSCode .vscode/tasks.json
        vscode_tasks = os.path.join(self.uproject.root_path, '.vscode', 'tasks.json')

        context = {}
        if os.path.exists(vscode_tasks):
            context = json.load(open(vscode_tasks, 'r'))

        context["tasks"] = []

        for configure in ("Development", "DebugGame", "Debug"):
            context["tasks"].append({
                "label": '{} {}Editor Build'.format(self.uproject.name, configure),
                "group": "build",
                "command": "cmd",
                "args": [
                    "/d",
                    "/c",
                    self.wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/Build.bat')),
                    '{}Editor'.format(self.uproject.name),
                    "Win64",
                    configure,
                    self.wpath(self.uproject.uproject_path),
                    #  "-waitmutex"
                ],
                "problemMatcher": "$msCompile",
                #  "dependsOn": [
                    #  "UnrealBuildTool Win64 Development Build"
                #  ],
                #  "type": "shell",
                "options": {
                    "cwd": "${workspaceRoot}"
                }
            })

        json.dump(context, open(vscode_tasks, 'w'), indent=4)

        # VSCode .vscode/launch.json
        vscode_launch = os.path.join(self.uproject.root_path, '.vscode', 'launch.json')

        context = {}
        if os.path.exists(vscode_launch):
            context = json.load(open(vscode_launch, 'r'))

        context["configurations"] = [
            {
                "name": "Attach",
                "type": "cppvsdbg",
                "request": "attach",
                "processId": "${command:pickProcess}"
            },
            {
                "name": "Development",
                "type": "cppvsdbg",
                "request": "launch",
                "program": self.wpath(os.path.join(self.uproject.project_root, 'Binaries/Win64/UE4Editor.exe')),
                "args": [
                    self.wpath(self.uproject.uproject_path),
                ],
                "cwd": "${workspaceRoot}"
            },
            {
                "name": "Debug",
                "type": "cppvsdbg",
                "request": "launch",
                "program": self.wpath(os.path.join(self.uproject.project_root, 'Binaries/Win64/UE4Editor.exe')),
                "args": [
                    self.wpath(self.uproject.uproject_path),
                    "-debug"
                ],
                "cwd": "${workspaceRoot}"
            },
        ]

        json.dump(context, open(vscode_launch, 'w'), indent=4)

    def _gen_compilation_databases(self, manifest):
        # JSON Compilation Database
        #  cmake_build = os.path.join(self.uproject.root_path, '.uproject', 'cmake.build')
        #  if os.path.exists(cmake_build):
            #  shutil.rmtree(cmake_build)
        #  os.makedirs(cmake_build)
        #  self.proc.subp(['touch', 'main.cpp'], cwd=cmake_build)
        #  self.proc.subp(['cmake', '..', '-DCMAKE_EXPORT_COMPILE_COMMANDS=on'], cwd=cmake_build)

        # gtags
        self.ctx.run(' '.join([
            'cd', self.uproject.project_root, '&&',
            'gtags', os.path.join(self.uproject.root_path, '.uproject', 'gtags.game')]),
            echo=True)
        self.ctx.run(' '.join([
            'cd', self.uproject.engine_root, '&&',
            'gtags', os.path.join(self.uproject.root_path, '.uproject', 'gtags.engine')]),
            echo=True)


class UhtManifest():
    class Module():
        def __init__(self, builder, context):
            self.name = context['Name']
            self.module_type = context['ModuleType']
            self.base_directory = context['BaseDirectory']
            self.include_base = context['IncludeBase']
            self.output_directory = context['OutputDirectory']
            self.classes_headers = context['ClassesHeaders']
            self.public_headers = context['PublicHeaders']
            self.private_headers = context['PrivateHeaders']
            #  self.pch = context['PCH']
            self.generated_cpp_filenamebase = context['GeneratedCPPFilenameBase']
            self.save_exported_headers = ['SaveExportedHeaders']
            self.uht_generated_code_version = ['UHTGeneratedCodeVersion']

            #  self.base_directory = upath(self.base_directory)
            self.include_base = builder.upath(self.include_base)
            self.output_directory = builder.upath(self.output_directory)
            #  self.classes_headers = [upath(x) for x in self.classes_headers]
            #  self.public_headers = [upath(x) for x in self.public_headers]
            #  self.private_headers = [upath(x) for x in self.private_headers]
            #  self.pch = upath(self.pch)
            #  self.generated_cpp_filenamebase = upath(self.generated_cpp_filenamebase)

    def __init__(self, builder, uproject):
        target = uproject.name + 'Editor'
        path = os.path.join(uproject.project_root, 'Intermediate', 'Build', 'Win64', target, 'Development', target + '.uhtmanifest')

        context = json.load(open(path, 'r'))
        self.is_game_target = context['IsGameTarget']
        self.root_local_path = context['RootLocalPath']
        self.root_build_path = context['RootBuildPath']
        self.target_name = context['TargetName']
        self.external_dependencies_file = context['ExternalDependenciesFile']
        self.modules = [self.Module(builder, x) for x in context['Modules']]

        #  self.root_local_path = upath(self.root_local_path)
        #  self.root_build_path = upath(self.root_build_path)
        #  self.external_dependencies_file = upath(self.external_dependencies_file)

