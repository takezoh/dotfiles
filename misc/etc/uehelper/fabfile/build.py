from .core import CoreBuilder

import os
import pathlib
import uuid


class BuildCommand(CoreBuilder):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.completed = []
        self.dependencies = {
            #  'UnrealBuildTool' : ('DotNETCommon/DotNETUtilities', ),
            'ShaderCompileWorker': ('UnrealBuildTool', ),
            'UnrealLightmass': ('UnrealBuildTool', ),
            }

    def _dependencies_build(func):
        def inner(self, target, command, configuration, platform, *args, **kwargs):
            if target in self.completed:
                return

            for dependency in self.dependencies.get(target, ()):
                self._run_build(dependency, command, 'Development', 'Win64')

            func(self, target, command, configuration, platform, *args, **kwargs)
            self.completed.append(target)

        return inner

    @_dependencies_build
    def _run_build(self, target, command, configuration, platform, *args, force=False, **kwargs):
       
        engine_root = self.uproject.engine_root

        cmd = None

        csproj = os.path.join(engine_root, 'Source/Programs/{}/{}.csproj'.format(target, os.path.basename(target)))
        if os.path.exists(csproj):
            command = command.lower()
            if command is 'rebuild':
                command = 'build'

            cmd = [
                self.wpath(os.path.join(engine_root, 'Build/BatchFiles/MSBuild.bat')),
                "/t:{}".format(command),
                self.wpath(csproj),
                "/p:GenerateFullPaths=true",
                "/p:DebugType=portable",
                "/p:Configuration={}".format(configuration),
                "/p:Platform=AnyCPU",
                "/verbosity:minimal"]
        else:
            cmd = [
                self.wpath(os.path.join(engine_root, 'Build/BatchFiles/{}.bat'.format(command.capitalize()))),
                target,
                platform,
                configuration,
                *args]

        if cmd:
            self.ctx.run('cmd-cp932.exe /c ' + ' '.join(cmd), echo=True)

    def build(self, target, command):
        target = target or self.uproject.name
        configuration = self.ctx['configuration']
        platform = self.ctx['platform']

        args = [
            self.wpath(self.uproject.uproject_path),
            ]

        for suffix in ('Editor', 'Client', 'Server', 'Program', 'Game'):
            if configuration.endswith(suffix):
                target = target + suffix
                configuration = configuration[:-len(suffix)]

        if platform != 'Win64' and target.endswith('Editor'):
            target = target[0:-len('Editor')]

        if not target.startswith(self.uproject.name):
            target = target[0:-len('Editor')]

        #  self._run_build('DotNETCommon/DotNETUtilities', command, 'Development', platform)
        #  self._run_build('UnrealBuildTool', command, 'Development', 'Win64')
        self._run_build('ShaderCompileWorker', command, 'Development', 'Win64')

        if platform == 'Android':
            def relative_to(base, dst, relative_count=0):
                try:
                    path = base.relative_to(dst)
                except ValueError:
                    dst = os.path.dirname(dst)
                    if dst == '/':
                        raise
                    return relative_to(base, dst, relative_count + 1)
                return os.path.join('/'.join(['..'] * relative_count), path)

            username = self.ctx.run('cmd.exe /c echo %USERNAME%', hide=True).stdout.strip()
            uproject_path = relative_to(pathlib.Path(self.uproject.uproject_path), os.path.join(self.uproject.engine_root, 'Binaries/Win64'))

            with open(os.path.join(self.uproject.project_root, 'Intermediate/Android/APK/assets/UE4CommandLine.txt'), 'w') as f:
                f.write('''{} -SessionId={} -SessionOwner='{}' -SessionName='{}' -messaging'''.format(
                   uproject_path, uuid.uuid4().hex, username, self.uproject.name))

        if platform == 'Linux':
            #  push_cmd('nkf', '-Lu', os.path.join(builder.uproject.engine_root, 'Build/BatchFiles/Linux/GenerateGDBInit.sh'),
                #  '|', 'bash')
            #  push_cmd('nkf', '-Lu', os.path.join(builder.uproject.engine_root, 'Build/BatchFiles/Linux/GenerateProjectFiles.sh'),
                #  '|', 'bash')
            pass
        else:
            self._run_build(target, command, configuration, platform, *args)

    def cook(self):
        #  Running: C:\dev\bkp\main\Engine\Binaries\Win64\UE4Editor-Cmd.exe C:\dev\bkp\main\BKP\Gargantua.uproject -run=Cook 
        #  -Map=BattleTest_01 
        #  -TargetPlatform=Android_ASTC -fileopenlog -unversioned -compressed 
        #  -abslog=C:\dev\bkp\main\Engine\Programs\AutomationTool\Saved\Cook-2019.01.08-14.11.30.txt 
        #  -stdout -CrashForUAT -unattended -NoLogTimes  -UTF8Output
        platform = self.ctx['platform']
        ue4exe = 'UE4Editor-Cmd.exe'
        cmdargs = [
            os.path.join(self.uproject.engine_root, 'Binaries/Win64/{}'.format(ue4exe)),
            self.wpath(self.uproject.uproject_path),
            '-run=Cook', 
            '-NoLogTimes', '-TargetPlatform={}'.format(platform), '-fileopenlog', '-unversioned', '-skipeditorcontent', 
            '-abslog={}'.format(self.wpath(os.path.join(self.uproject.project_root, 'Saved/Logs/HelperCook.txt'))), '-stdout',
            '-unattended',  '-UTF8Output']

        self.ctx.run(' '.join(cmdargs), echo=True)

    def _package(self, flavor, *args):
        configuration = self.ctx['configuration']
        platform = self.ctx['platform']
        username = self.ctx.run('cmd.exe /c echo %USERNAME%', hide=True).stdout.strip()

        cmdargs = [
            self.wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/RunUAT.bat')),
            '-ScriptsForProject={}'.format(self.wpath(self.uproject.uproject_path)),
            'BuildCookRun',
            '-nocompileeditor',
            '-nop4',
            '-project={}'.format(self.wpath(self.uproject.uproject_path)),
            '-SkipCookingEditorContent', 
            *args,
            '-clientconfig={}'.format(configuration), 
            '-prereqs', '-targetplatform={}'.format(platform), '-utf8output']

        if platform in ('Android', ):
            cmdargs += [
                '-serverconfig={}'.format(configuration),
                '-addcmdline="-SessionId={} -SessionOwner=\'{}\' -SessionName=\'{}\' -messaging"'.format(uuid.uuid4().hex, username, self.uproject.name),
                ]

        if configuration in ('Shipping', ):
            cmdargs += ['-nodebuginfo']
        else:
            cmdargs += ['-debuginfo', '-CrashReporter']
            if '-cook' in cmdargs:
                cmdargs.append('-iterativecooking')

        if flavor:
            cmdargs.append('-cookflavor={}'.format(flavor)) 

        self.ctx.run('cmd.exe /c ' + ' '.join(cmdargs), echo=True)

    def package(self, flavor):
# Parsing command line: -ScriptsForProject=C:/dev/bkp/main/BKP/Gargantua.uproject BuildCookRun -project=C:/dev/bkp/main/BKP/Gargantua.uproject -noP4 -clientconfig=Development -serverconfig=Development -nocompileeditor -ue4exe=UE4Editor-Cmd.exe -utf8output -platform=Android_ASTC -targetplatform=Android -cookflavor=ASTC -build -cook -map= -unversionedcookedcontent -pak -compressed -stage -deploy -cmdline=" -Messaging" -device=Android_ASTC@1PASH3M1FK8113 -addcmdline="-SessionId=7DDA49E04148D77367DBB299BCE4B638 -SessionOwner='gondo' -SessionName='New Profile 0' -messaging" -run -compile
# Running: C:\dev\bkp\main\Engine\Binaries\DotNET\UnrealBuildTool.exe Gargantua Android Development -Project=C:\dev\bkp\main\BKP\Gargantua.uproject  C:\dev\bkp\main\BKP\Gargantua.uproject -NoUBTMakefiles  -remoteini="C:\dev\bkp\main\BKP" -skipdeploy -noxge -generatemanifest -NoHotReload
# Running: C:\dev\bkp\main\Engine\Binaries\DotNET\UnrealBuildTool.exe Gargantua Android Development -Project=C:\dev\bkp\main\BKP\Gargantua.uproject  C:\dev\bkp\main\BKP\Gargantua.uproject -NoUBTMakefiles  -remoteini="C:\dev\bkp\main\BKP" -skipdeploy -noxge -NoHotReload -ignorejunk
# Running: C:\dev\bkp\main\Engine\Binaries\Win64\UnrealPak.exe C:\dev\bkp\main\BKP\Saved\StagedBuilds\Android_ASTC\Gargantua\Content\Paks\Gargantua-Android_ASTC.pak -create=C:\dev\bkp\main\Engine\Programs\AutomationTool\Saved\Logs\PakList_Gargantua-Android_ASTC.txt -encryptionini -enginedir="C:\dev\bkp\main\Engine" -projectdir="C:\dev\bkp\main\BKP" -platform=Android -abslog="C:\dev\bkp\main\Engine\Programs\AutomationTool\Saved\Logs\PakLog_Gargantua-Android_ASTC.log" -order=C:\dev\bkp\main\BKP\Build\Android_ASTC\FileOpenOrder\CookerOpenOrder.log -UTF8Output -multiprocess

        self._package(flavor, 
           '-build', '-compile', '-cook', '-stage', '-pak', '-archive', '-package', '-compressed', 
           '-archivedirectory={}'.format(self.wpath(os.path.join(self.uproject.project_root, 'Saved/Packages'))),
           '-mapsonly')

    def deploy(self, mapstocook, flavor, opts):
        if not mapstocook:
            result = self.select_map()
            selected = result.stdout.strip()
            print("Selected Map: {}".format(selected))
            mapstocook = os.path.basename(selected[:-5])

        self._package(flavor, 
            #  '-build', '-cook', 
            '-nocompile', '-stage', '-pak', '-manifests', '-deploy', '-compressed', 
            '-map={}'.format(mapstocook), '-iterativedeploy',
            '-cmdline="{}"'.format(mapstocook),
            *(opts or '').split(' '))

    def uat(self):
        cmdargs = [
            self.wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/RunUAT.bat')),
            ]
        self.ctx.run('/mnt/c/Windows/System32/cmd.exe /c ' + ' '.join(cmdargs))

