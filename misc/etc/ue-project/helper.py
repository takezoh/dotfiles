#!/usr/bin/env python3
import os
import sys
import json
import glob
import subprocess

UNREAL_VERSION_SELECTOR="/mnt/c/Program Files (x86)/Epic Games/Launcher/Engine/Binaries/Win64/UnrealVersionSelector.exe"


def wslpath(winpath):
    if not winpath:
        return winpath
    if winpath[-1] == '\\':
        winpath = winpath[0:-1]
    return subprocess.check_output(r'wslpath -au "{}"'.format(winpath), shell=True).strip().decode('utf-8')


class UProject():
    def __init__(self, uproject_path):
        self.uproject_path = uproject_path
        self.root_path = os.path.dirname(os.path.dirname(uproject_path))
        self.name = os.path.basename(uproject_path)[:-len('.uproject')]
        self.project_root = os.path.join(root_path, os.path.dirname(uproject_path))
        self.engine_root = os.path.join(root_path, 'Engine')


class UhtManifest():
    class Module():
        def __init__(self, context):
            self.name = context['Name']
            self.module_type = context['ModuleType']
            self.base_directory = context['BaseDirectory']
            self.include_base = context['IncludeBase']
            self.output_directory = context['OutputDirectory']
            self.classes_headers = context['ClassesHeaders']
            self.public_headers = context['PublicHeaders']
            self.private_headers = context['PrivateHeaders']
            self.pch = context['PCH']
            self.generated_cpp_filenamebase = context['GeneratedCPPFilenameBase']
            self.save_exported_headers = ['SaveExportedHeaders']
            self.uht_generated_code_version = ['UHTGeneratedCodeVersion']

            #  self.base_directory = wslpath(self.base_directory)
            self.include_base = wslpath(self.include_base)
            self.output_directory = wslpath(self.output_directory)
            #  self.classes_headers = [wslpath(x) for x in self.classes_headers]
            #  self.public_headers = [wslpath(x) for x in self.public_headers]
            #  self.private_headers = [wslpath(x) for x in self.private_headers]
            #  self.pch = wslpath(self.pch)
            #  self.generated_cpp_filenamebase = wslpath(self.generated_cpp_filenamebase)

    def __init__(self, uproject):
        target = uproject.name + 'Editor'
        path = os.path.join(uproject.project_root, 'Intermediate', 'Build', 'Win64', target, 'Development', target + '.uhtmanifest')

        context = json.load(open(path, 'r'))
        self.is_game_target = context['IsGameTarget']
        self.root_local_path = context['RootLocalPath']
        self.root_build_path = context['RootBuildPath']
        self.target_name = context['TargetName']
        self.external_dependencies_file = context['ExternalDependenciesFile']
        self.modules = [self.Module(x) for x in context['Modules']]

        #  self.root_local_path = wslpath(self.root_local_path)
        #  self.root_build_path = wslpath(self.root_build_path)
        #  self.external_dependencies_file = wslpath(self.external_dependencies_file)


class Command():
    def __init__(self, current_dir):
        self.processes = []
        self.uproject = None

        while current_dir != "/":
            result = glob.glob(current_dir, '*/*.uproject')
            if result:
                print ('Found {}'.format(result[0]))
                self.uproject = UProject(result[0])
                return

            current_dir = os.path.dirname(current_dir)

        raise "Not Found *.uproject"

    def __call__(self, cmd, *args):
        self.__dict__[cmd.replace('-', '_')](*args)

    def maps(self, *args):
        subprocess.check_call(['rg', '-g', '*.umap', '--files', wslpath(os.path.join(self.uproject.project_root, 'Content'))],
                stdout=subprocess.PIPE, shell=True)

    def packages(self, *args):
        target_dir = self.uproject.project_root
        for _ in range(2):
            if target_dir == '/':
                raise
            if os.path.exists(os.path.join(target_dir, 'packages')):
                break
            target_dir = os.path.dirname(target_dir)

        if os.path.exists(os.path.join(target_dir, 'packages')):
            target_dir = os.path.join(target_dir, 'packages')

        subprocess.check_call(['rg', '-g', '{}.exe'.format(self.uproject.name), '--files', target_dir, '|', 'rg', '/WindowsNoEditor/'],
                stdout=subprocess.PIPE, shell=True)

    def launch(self, *args):
        if args[0].endswith('.exe'):
            subprocess.check_call(args + ['-fullcrashdump'])
            return

        os.chdir(self.uproject.root_path)

        cmdargs = [UNREAL_VERSION_SELECTOR, '/editor']

        editor = os.path.join(self.uproject.engine_root, 'Binaries/Win64/UE4Editor.exe')
        if os.path.exists(editor):
            cmdargs = ['open', wslpath(editor)]

        cmdargs = cmdargs + [wslpath(self.uproject.uproject_path)] + args + ['-skipcompile', '-fullcrashdump']
        subprocess.check_call(cmdargs, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)

    def build(self, command, configuration, *args):
        self._build_internal(command, self.uproject.name, configuration, 'Win64', wslpath(self.uproject.uproject_path), *args)

    def _build_internal(self, command, target, configuration, platform, *args):
        for suffix in ('Editor', 'Client', 'Server'):
            if configuration.endswith(suffix):
                target = target + suffix
                configuration = configuration[:-len(suffix)]

        #  self._build_unreal_buildtool(command, configuration, platform)

        cmdargs = ['wcmd',
            wslpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/{}.bat'.format(command))),
            target,
            platform,
            configuration]

        subprocess.check_call(cmdargs + args + ['-waitmutex', '-FromMsBuild'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)

    def _build_unreal_buildtool(self, command, configuration, platform):
        command = command.lower()
        if command is 'rebuild':
            command = 'build'

        cmdargs = ['wcmd',
            wslpath(os.uproject.engine_root, 'Build/BatchFiles/MSBuild.bat'),
            "/t:{}".format(command),
            "Engine/Source/Programs/UnrealBuildTool/UnrealBuildTool.csproj",
            "/p:GenerateFullPaths=true",
            "/p:DebugType=portable",
            "/p:Configuration={}".format(configuration),
            "/verbosity:minimal"]

        subprocess.check_call(cmdargs, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)

    def generate_project_files(self, *args):
        cmdargs = [UNREAL_VERSION_SELECTOR, '/projectfiles']

        builder = os.path.join(self.uproject.engine_root, 'Build/BatchFiles/GenerateProjectFiles.bat')
        if os.path.exists(builder):
            cmdargs = ['wcmd', wslpath(builder)]

        cmdargs = cmdargs + [wslpath(self.uproject.uproject_path), '-Game', '-Engine', '-2017', '-VSCode'] + args
        subprocess.check_call(cmdargs, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)

        manifest = UhtManifest(self.uproject)

        self._configure(manifest)
        self._patch_vscode_project(manifest)
        self._gen_compilation_databases(manifest)

    def _configure(self, manifest):
        # fetch include directories
        include_dirs = []
        for m in manifest.modules:
            ii = subprocess.check_output('find "{}" -type d'.format(m.include_base), shell=True).decode('utf-8').strip()
            include_dirs[len(include_dirs):] = ii.split('\n')
            include_dirs.append(m.output_directory)

        # copy files
        for frm, to, rep in [
                ('ignore', '.ignore', {}),
                ('project.gtags.conf', os.path.join('.uproject', 'gtags.game', 'gtags.conf'), {}),
                ('engine.gtags.conf', os.path.join('.uproject', 'gtags.engine', 'gtags.conf'), {}),
                ('globalrc', '.globalrc', {
                        'project_root': self.uproject.project_root,
                        'engine_root': self.uproject.engine_root,
                        'gtagsdb_root': os.path.join(self.uproject.root_path, '.uproject'),
                    }),
                ('globalrc.template.bat', 'globalrc.bat', {
                        'project_root': self.uproject.project_root,
                        'engine_root': self.uproject.engine_root,
                        'gtagsdb_root': os.path.join(self.uproject.root_path, '.uproject'),
                    }),
                ('clang.template', '.clang', {
                        'compilation_database': os.path.join(self.uproject.root_path, '.uproject'),
                    }),
                ('CMakeLists.template.txt', os.path.join('.uproject', 'CMakeLists.txt'), {
                        'include_directories': ' '.join(['"{}"'.format(x) for x in include_dirs]),
                    }),
                ]:
            open(os.path.join(self.uproject.root_path, to), 'w').write(
                open(os.environ['HOME'] + '/.dotfiles/misc/etc/ue-project/' + frm, 'r').read().format(rep))

    def _patch_vscode_project(self, manifest):
        # VSCode UE4.code-workspace
        vscode_project = os.path.join(self.uproject.project_root, 'UE4.code-workspace')
        context = json.load(open(vscode_project, 'r'))
        context["settings"]["codegnuglobal.executable"] = "globalrc.bat"
        context["settings"]["codegnuglobal.autoupdate"] = True
        json.dump(context, open(vscode_project, 'w'), indent=4)

        # VSCode .vscode/c_cpp_properties.json
        #  vscode_c_cpp_properties = os.path.join(self.uproject.project_root, '.vscode', 'c_cpp_properties.json')

        # VSCode .vscode/tasks.json
        vscode_tasks = os.path.join(self.uproject.project_root, '.vscode', 'tasks.json')
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
                    wslpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/Build.bat')),
                    '{}Editor'.format(self.uproject.name),
                    "Win64",
                    configure,
                    wslpath(self.uproject.uproject_path),
                    "-waitmutex"
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
        vscode_launch = os.path.join(self.uproject.project_root, '.vscode', 'launch.json')
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
                "program": wslpath(os.path.join(self.uproject.project_root, 'Binaries/Win64/UE4Editor.exe')),
                "args": [
                    wslpath(self.uproject.uproject_path),
                ],
                "cwd": "${workspaceRoot}"
            },
            {
                "name": "Debug",
                "type": "cppvsdbg",
                "request": "launch",
                "program": wslpath(os.path.join(self.uproject.project_root, 'Binaries/Win64/UE4Editor.exe')),
                "args": [
                    wslpath(self.uproject.uproject_path),
                    "-debug"
                ],
                "cwd": "${workspaceRoot}"
            },
        ]

        json.dump(context, open(vscode_launch, 'w'), indent=4)

    def _gen_compilation_databases(self, manifest):
        # JSON Compilation Database
        cmake_command = 'rm -rf "{0}" && mkdir -p "{0}" && cd "{0}" && cmake ../.. -DCMAKE_EXPORT_COMPILE_COMMANDS=on'.format(os.path.join(self.uproject.root_path, '.uproject', 'cmake.build'))
        processes.append(subprocess.Popen(cmake_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True))

        # gtags
        gtags_command = 'cd "{}" && gtags "{}"'.format(
                os.path.join(self.uproject.project_root),
                os.path.join(self.uproject.root_path, '.uproject', 'gtags.game'))
        processes.append(subprocess.Popen(, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True))

        gtags_command = 'cd "{}" && gtags "{}"'.format(
                os.path.join(self.uproject.engine_root),
                os.path.join(self.uproject.root_path, '.uproject', 'gtags.engine'))
        processes.append(subprocess.Popen(, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True))

    def join(self):
        for p in self.processes:
            p.join()


if __name__ == '__main__':
    command = Command(os.getcwd())
    command(sys.argv[1], *sys.argv[2:])
    command.join()

#    for k, v in uproject.__dict__.items():
#        print (k,v)
#
#    for k, v in manifest.__dict__.items():
#        if k != 'modules':
#            print (k, v)
#
#    #  for k, v in manifest.modules[0].__dict__.items():
#        #  print (k, v)
#
#    for m in manifest.modules:
#        if m.base_directory != m.include_base:
#            print ('name', m.name)
#            print ('base', m.base_directory)
#            print ('inc', m.include_base)
#        #  for k, v in m.__dict__.items():
#            #  if not k in ('base_directory', 'include_base', 'output_directory'):
#                #  continue
#            #  print (k, v)
