#!/usr/bin/env python3
import os
import sys
import json
import glob
import subprocess
import shutil

UNREAL_VERSION_SELECTOR = "/mnt/c/Program Files (x86)/Epic Games/Launcher/Engine/Binaries/Win64/UnrealVersionSelector.exe"
UNREAL_ENGINE_INSTALL_ROOT = '/mnt/c/Program Files/Epic Games'

class HelperError(ValueError): pass


def upath(wpath):
    if not wpath:
        return wpath
    if wpath[-1] == '\\':
        wpath = wpath[0:-1]
    return subp_output(['wslpath', '-au',  wpath]).strip()


def wpath(upath):
    if not upath:
        return upath
    return subp_output(['wslpath', '-aw',  upath]).strip()


def subp_output(args):
    p = subprocess.run(args, stdout=subprocess.PIPE, shell=False)
    p.check_returncode()
    return p.stdout.decode('utf-8')


class Proc():
    def __init__(self):
        self.processes = []

    def subp(self, args, cwd=None):
        if args[0] == 'wcmd':
            args = ['cmd.exe', '/c'] + args[1:]

        p = subprocess.Popen(args, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=cwd, shell=False)

        if type(p.args) is list:
            print ("exec: " + ' '.join(p.args))
        else:
            print ('exec: ' + p.args)

        self.processes.append(p)
        return p

    def join(self, processes=None):
        processes = processes or self.processes

        def read(stream, outstream, linebuffer, readsize=0):
            if stream.readable():
                if readsize:
                    linebuffer += stream.read(readsize).decode('utf-8').replace('\r\n', '\n')
                else:
                    linebuffer += stream.read().decode('utf-8').replace('\r\n', '\n')

                temp = linebuffer.rsplit('\n', 1)
                if len(temp) > 1:
                    linebuffer = temp[1]
                    print(temp[0].strip(), file=outstream)
                else:
                    linebuffer = temp[0]

            return linebuffer

        for p in processes:
            p.stdout_line_buffer = ''
            p.stderr_line_buffer = ''

        error_codes = []
        while processes:
            for p in processes:
                if p.returncode is None:
                    p.poll()
                    p.stdout_line_buffer = read(p.stdout, sys.stdout, p.stdout_line_buffer, 32)
                    p.stderr_line_buffer = read(p.stderr, sys.stderr, p.stderr_line_buffer, 32)
                else:
                    processes.remove(p)
                    if p.returncode is not 0:
                        error_codes.append(p)
                    read(p.stdout, sys.stdout, p.stdout_line_buffer)
                    read(p.stderr, sys.stderr, p.stderr_line_buffer)

        if any(error_codes):
            raise OSError(error_codes)


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
            self.engine_root = os.path.join(UNREAL_ENGINE_INSTALL_ROOT, 'UE_' + self.engine_association, 'Engine')


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

            #  self.base_directory = upath(self.base_directory)
            self.include_base = upath(self.include_base)
            self.output_directory = upath(self.output_directory)
            #  self.classes_headers = [upath(x) for x in self.classes_headers]
            #  self.public_headers = [upath(x) for x in self.public_headers]
            #  self.private_headers = [upath(x) for x in self.private_headers]
            #  self.pch = upath(self.pch)
            #  self.generated_cpp_filenamebase = upath(self.generated_cpp_filenamebase)

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

        #  self.root_local_path = upath(self.root_local_path)
        #  self.root_build_path = upath(self.root_build_path)
        #  self.external_dependencies_file = upath(self.external_dependencies_file)


class Command():
    def __init__(self, proc, current_dir):
        self.proc = proc
        self.uproject = None

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

    def __call__(self, cmd, *args):
        getattr(self, cmd.replace('-', '_'))(*args)

    def maps(self, *args):
        subprocess.Popen(['rg', '-g', '*.umap', '--files', os.path.join(self.uproject.project_root, 'Content')],
                stdout=subprocess.STDOUT, shell=True).wait()

    def packages(self, *args):
        target_dir = self.uproject.project_root
        for _ in range(2):
            if target_dir == '/':
                raise HelperError()
            if os.path.exists(os.path.join(target_dir, 'packages')):
                break
            target_dir = os.path.dirname(target_dir)

        if os.path.exists(os.path.join(target_dir, 'packages')):
            target_dir = os.path.join(target_dir, 'packages')

        p1 = subprocess.Popen(['rg', '-g', '{}.exe'.format(self.uproject.name), '--files', target_dir], stdout=subprocess.PIPE, shell=True)
        p2 = subprocess.Popen(['rg', '/WindowsNoEditor/'], stdin=p1.stdout, stdout=subprocess.STDOUT, shell=True)
        p1.wait()
        p1.stdout.close()
        p2.wait()

    def launch_command(self, *args):
        if len(args) > 0 and args[0].endswith('.exe'):
            cmd = list(args) + ['-fullcrashdump']
            print (' '.join(cmd), file=sys.stderr)
            print (' '.join(cmd), file=sys.stdout)
            return

        os.chdir(self.uproject.root_path)

        cmdargs = [UNREAL_VERSION_SELECTOR, '/editor']

        editor = os.path.join(self.uproject.engine_root, 'Binaries/Win64/UE4Editor.exe')
        if os.path.exists(editor):
            cmdargs = [editor]

        cmd = cmdargs + [wpath(self.uproject.uproject_path)] + list(args) + ['-skipcompile', '-fullcrashdump']
        print (' '.join(cmd), file=sys.stderr)
        print (' '.join(cmd), file=sys.stdout)

    def project_root(self, *args):
        print (self.uproject.project_root)

    def engine_root(self, *args):
        print (self.uproject.engine_root)

    def build_command(self, command, configuration, *args):
        cmd = _generate_build_command_internal(self.proc,
                self.uproject.engine_root,
                self.uproject.name,
                'Win64',
                command,
                configuration,
                wpath(self.uproject.uproject_path),
                *args)
        print (' '.join(cmd))

    def project_files_command(self, *args):
        cmdargs = [UNREAL_VERSION_SELECTOR, '/projectfiles']

        builder = os.path.join(self.uproject.engine_root, 'Build/BatchFiles/GenerateProjectFiles.bat')
        if os.path.exists(builder):
            cmdargs = ['cmd.exe', '/c', wpath(builder)]

        cmd = ' '.join(cmdargs + [wpath(self.uproject.uproject_path), '-Game', '-Engine', '-2017', '-VSCode'] + list(args))
        print('exec: ' + cmd, file=sys.stderr)
        print(cmd, file=sys.stdout)

    def generate_user_support_files(self, *args):
        manifest = UhtManifest(self.uproject)

        self._configure(manifest)
        self._patch_vscode_project(manifest)
        self._gen_compilation_databases(manifest)

    def _configure(self, manifest):
        # fetch include directories
        include_dirs = []
        source_directory = ''
        for m in manifest.modules:
            ii = subp_output(['find', m.include_base, '-type', 'd']).strip()
            include_dirs[len(include_dirs):] = ii.split('\n')
            include_dirs.append(m.output_directory)
            if m.name == self.uproject.name:
                source_directory = upath(m.base_directory)

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
                        'project_root': self.uproject.project_root,
                        'engine_root': self.uproject.engine_root,
                        'gtagsdb_root': os.path.join(self.uproject.root_path, '.uproject'),
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
            frm = os.path.join(os.path.dirname(os.path.abspath(__file__)), frm)
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
                    wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/Build.bat')),
                    '{}Editor'.format(self.uproject.name),
                    "Win64",
                    configure,
                    wpath(self.uproject.uproject_path),
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
                "program": wpath(os.path.join(self.uproject.project_root, 'Binaries/Win64/UE4Editor.exe')),
                "args": [
                    wpath(self.uproject.uproject_path),
                ],
                "cwd": "${workspaceRoot}"
            },
            {
                "name": "Debug",
                "type": "cppvsdbg",
                "request": "launch",
                "program": wpath(os.path.join(self.uproject.project_root, 'Binaries/Win64/UE4Editor.exe')),
                "args": [
                    wpath(self.uproject.uproject_path),
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
        self.proc.subp(['gtags', os.path.join(self.uproject.root_path, '.uproject', 'gtags.game')], cwd=self.uproject.project_root)
        self.proc.subp(['gtags', os.path.join(self.uproject.root_path, '.uproject', 'gtags.engine')], cwd=self.uproject.engine_root)


def _generate_build_command_internal(proc, engine_root, target, platform, command, configuration, *args):
    for suffix in ('Editor', 'Client', 'Server'):
        if configuration.endswith(suffix):
            target = target + suffix
            configuration = configuration[:-len(suffix)]

    buildtool_cmd = _generate_unreal_buildtool_build_command(proc, engine_root, command, configuration, platform)

    build_cmd = ['cmd.exe', '/c',
        wpath(os.path.join(engine_root, 'Build/BatchFiles/{}.bat'.format(command.capitalize()))),
        target,
        platform,
        configuration] + list(args) + ['-WaitMutex', '-FromMsBuild', '-2017']

    print('exec: ' + ' '.join(buildtool_cmd), file=sys.stderr)
    print('exec: ' + ' '.join(build_cmd), file=sys.stderr)
    return buildtool_cmd + ['&&'] + build_cmd


def _generate_unreal_buildtool_build_command(proc, engine_root, command, configuration, platform):
    command = command.lower()
    if command is 'rebuild':
        command = 'build'

    return ['cmd.exe', '/c',
        wpath(os.path.join(engine_root, 'Build/BatchFiles/MSBuild.bat')),
        "/t:{}".format(command),
        wpath(os.path.join(engine_root, 'Source/Programs/UnrealBuildTool/UnrealBuildTool.csproj')),
        "/p:GenerateFullPaths=true",
        "/p:DebugType=portable",
        "/p:Configuration={}".format(configuration),
        "/verbosity:minimal"]


def _generate_project_files(proc, engine_root, *args):
    cmdargs = [UNREAL_VERSION_SELECTOR, '/projectfiles']

    builder = os.path.join(engine_root, 'Build/BatchFiles/GenerateProjectFiles.bat')
    if os.path.exists(builder):
        cmdargs = ['wcmd', wpath(builder)]

    proc.subp(cmdargs + ['-2017', '-VSCode'] + list(args))
    proc.join()


def _get_engine_root():
    current_dir = os.getcwd()
    while current_dir != "/":
        if os.path.exists(os.path.join(current_dir, 'Engine')):
            return os.path.join(current_dir, 'Engine')

        current_dir = os.path.dirname(current_dir)

    raise HelperError("Not Found Engine Directory.")


def fallback_non_uproject(proc, cmd, *args):
    engine_root = _get_engine_root()

    if cmd == "generate-project-files" and \
            _generate_project_files(proc, engine_root, *args):
        return True

    if cmd == 'build' and \
            _build_internal(proc,
                engine_root,
                'UE4',
                'Win64',
                *args):
        return True

    return False


def command(proc, cmd, *args):
    command = Command(proc, os.getcwd())
    command(cmd, *args)


def guarded_main(func, *args):
    proc = Proc()
    try:
        func(proc, *args)
        return True
    except HelperError as e:
        print (e, file=sys.stderr)
        return False
    finally:
        proc.join()


if __name__ == '__main__':
    cmd = sys.argv[1]
    args = sys.argv[2:]

    if 'test' != cmd:
        if not guarded_main(command, cmd, *args):
            if not guarded_main(fallback_non_uproject, cmd, *args):
                sys.exit(1)
        sys.exit(0)

    command = Command(None, os.getcwd())
    manifest = UhtManifest(command.uproject)

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
    for m in manifest.modules:
       if m.base_directory != m.include_base:
           if m.name == 'Gargantua':
               print ('name', m.name)
               print ('base', m.base_directory)
               print ('inc', m.include_base)
               print ('pub', m.public_headers)
       #  for k, v in m.__dict__.items():
           #  if not k in ('base_directory', 'include_base', 'output_directory'):
               #  continue
           #  print (k, v)
