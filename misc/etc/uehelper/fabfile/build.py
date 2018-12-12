from .core import CoreBuilder

import os


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
                self._run_build(dependency, command, 'Debug', 'Win64')

            if target == 'ShaderCompileWorker' and configuration != 'Development':
                func(self, 'ShaderCompileWorker', command, 'Development', 'Win64')

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
                *args] #, '-WaitMutex', '-2017'] # '-FromMsBuild', #, '-CanSkipLink', '-Define', 'USE_LOGGING_IN_SHIPPING=1']

        if cmd:
            #  self.ctx.run('/mnt/c/Windows/System32/cmd.exe /c ' + ' '.join(cmd + self.opts), echo=True)
            self.ctx.run('cmd.exe /c ' + ' '.join(cmd + self.opts), echo=True)

#  ..\..\Build\BatchFiles\Build.bat UE4Editor Win64 Development -WaitMutex -FromMsBuild -2017

    def build(self, target, command, configuration, platform):
        target = target or self.uproject.name
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

        #  self._run_build('DotNETCommon/DotNETUtilities', command, 'Debug', platform)
        self._run_build('UnrealBuildTool', command, 'Debug', 'Win64')
        self._run_build('ShaderCompileWorker', command, 'Debug', 'Win64')

        if platform == 'Linux':
            #  push_cmd('nkf', '-Lu', os.path.join(builder.uproject.engine_root, 'Build/BatchFiles/Linux/GenerateGDBInit.sh'),
                #  '|', 'bash')
            #  push_cmd('nkf', '-Lu', os.path.join(builder.uproject.engine_root, 'Build/BatchFiles/Linux/GenerateProjectFiles.sh'),
                #  '|', 'bash')
            pass
        else:
            self._run_build(target, command, configuration, platform, *args)

    def cook(self, platform):
        ue4exe = 'UE4Editor-Cmd.exe'
        cmdargs = [
            os.path.join(self.uproject.engine_root, 'Binaries/Win64/{}'.format(ue4exe)),
            self.wpath(self.uproject.uproject_path),
            '-run=Cook', 
            '-NoLogTimes', '-TargetPlatform={}'.format(platform), '-fileopenlog', '-unversioned', '-skipeditorcontent', 
            '-abslog={}'.format(self.wpath(os.path.join(self.uproject.project_root, 'Saved/Logs/HelperCook.txt'))), '-stdout',
            #  '-CrashForUAT', 
            '-unattended',  '-UTF8Output']

        self.ctx.run(' '.join(cmdargs + self.opts), echo=True)

    def package(self, configuration, platform, flavor):
        ue4exe = 'UE4Editor-Cmd.exe'

# Parsing command line: -ScriptsForProject=C:/dev/bkp/main/BKP/Gargantua.uproject BuildCookRun -project=C:/dev/bkp/main/BKP/Gargantua.uproject -noP4 -clientconfig=Development -serverconfig=Development -nocompileeditor -ue4exe=UE4Editor-Cmd.exe -utf8output -platform=Android_ASTC -targetplatform=Android -cookflavor=ASTC -build -cook -map= -unversionedcookedcontent -pak -compressed -stage -deploy -cmdline=" -Messaging" -device=Android_ASTC@1PASH3M1FK8113 -addcmdline="-SessionId=7DDA49E04148D77367DBB299BCE4B638 -SessionOwner='gondo' -SessionName='New Profile 0' -messaging" -run -compile
# Running: C:\dev\bkp\main\Engine\Binaries\DotNET\UnrealBuildTool.exe Gargantua Android Development -Project=C:\dev\bkp\main\BKP\Gargantua.uproject  C:\dev\bkp\main\BKP\Gargantua.uproject -NoUBTMakefiles  -remoteini="C:\dev\bkp\main\BKP" -skipdeploy -noxge -generatemanifest -NoHotReload
# Running: C:\dev\bkp\main\Engine\Binaries\DotNET\UnrealBuildTool.exe Gargantua Android Development -Project=C:\dev\bkp\main\BKP\Gargantua.uproject  C:\dev\bkp\main\BKP\Gargantua.uproject -NoUBTMakefiles  -remoteini="C:\dev\bkp\main\BKP" -skipdeploy -noxge -NoHotReload -ignorejunk
# Running: C:\dev\bkp\main\Engine\Binaries\Win64\UE4Editor-Cmd.exe C:\dev\bkp\main\BKP\Gargantua.uproject -run=Cook  -NoLogTimes -TargetPlatform=Android_ASTC -fileopenlog -unversioned -abslog=C:\dev\bkp\main\Engine\Programs\AutomationTool\Saved\Cook-2018.11.19-21.28.15.txt -stdout -CrashForUAT -unattended  -UTF8Output
# Running: C:\dev\bkp\main\Engine\Binaries\Win64\UnrealPak.exe C:\dev\bkp\main\BKP\Saved\StagedBuilds\Android_ASTC\Gargantua\Content\Paks\Gargantua-Android_ASTC.pak -create=C:\dev\bkp\main\Engine\Programs\AutomationTool\Saved\Logs\PakList_Gargantua-Android_ASTC.txt -encryptionini -enginedir="C:\dev\bkp\main\Engine" -projectdir="C:\dev\bkp\main\BKP" -platform=Android -abslog="C:\dev\bkp\main\Engine\Programs\AutomationTool\Saved\Logs\PakLog_Gargantua-Android_ASTC.log" -order=C:\dev\bkp\main\BKP\Build\Android_ASTC\FileOpenOrder\CookerOpenOrder.log -UTF8Output -multiprocess

        cmdargs = [
            self.wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/RunUAT.bat')),
            '-ScriptsForProject={}'.format(self.wpath(self.uproject.uproject_path)),
            'BuildCookRun',
            '-nocompileeditor',
            '-nop4',
            '-project={}'.format(self.wpath(self.uproject.uproject_path)),
            '-cook', '-stage', '-archive', '-mapsonly',
            '-archivedirectory={}'.format(self.wpath(os.path.join(self.uproject.project_root, 'Saved/Packages'))),
            '-package', '-clientconfig={}'.format(configuration), '-ue4exe={}'.format(ue4exe), '-compressed', '-SkipCookingEditorContent',
            '-pak', '-prereqs', '-nodebuginfo', '-targetplatform={}'.format(platform), '-build', '-CrashReporter', '-utf8output', '-compile']

        if flavor:
            cmdargs.append('-cookflavor={}'.format(flavor)) 

        self.ctx.run('/mnt/c/Windows/System32/cmd.exe /c ' + ' '.join(cmdargs + self.opts), echo=True)

    def uat(self):
        cmdargs = [
            self.wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/RunUAT.bat')),
            ]
        self.ctx.run('/mnt/c/Windows/System32/cmd.exe /c ' + ' '.join(cmdargs + self.opts))

