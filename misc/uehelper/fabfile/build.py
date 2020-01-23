from .core import CoreBuilder

import os
import pathlib
import uuid
import time
import shutil


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
                *args,
                '-fullcrashdump']

        if cmd:
            self.ctx.run('time cmd-cp932.exe /c ' + ' '.join(cmd), echo=True)

    def build(self, target, command, opts):
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

        if not self.uproject.has_modules:
            target = 'UE4Editor'

        import configparser
        console_variables_path = os.path.join(self.uproject.project_root, 'Saved/Config/ConsoleVariables.ini')
        section_name = 'Startup'
        config = configparser.ConfigParser()
        config.read(console_variables_path)
        if not config.has_section(section_name):
            config.add_section(section_name)
        config.set(section_name, 'r.ShaderDevelopmentMode', '1')
        config.set(section_name, 'r.DumpShaderDebugInfo', '1')
        config.set(section_name, 'r.DumpShaderDebugShortNames', '0')
        config.set(section_name, 'r.DumpShaderDebugWorkerCommandLine', '1')
        try:
            os.makedirs(os.path.dirname(console_variables_path))
        except OSError:
            pass
        with open(console_variables_path, 'w') as f:
            config.write(f)

        defines = [
                'ALLOW_PROFILEGPU_IN_TEST=1',
                'ENABLE_STATNAMEDEVENTS=UE_BUILD_TEST',
                #  'ENABLE_STATNAMEDEVENTS_UOBJECT=1',
                #  'ALLOW_HITCH_DETECTION=1',
                'USE_LOGGING_IN_SHIPPING=!UE_BUILD_SHIPPING',
                ]
        defines = '-UniqueBuildEnvironment ' + ' '.join(['"-Define:{}"'.format(x) for x in defines])
        defines = ''

        self._run_build('DotNETCommon/DotNETUtilities', command, 'Development', platform)
        self._run_build('UnrealBuildTool', command, 'Development', 'Win64')
        self._run_build('AutomationTool', command, 'Development', 'Win64')
        self._run_build('ShaderCompileWorker', command, 'Development', 'Win64', defines)

        if platform == 'Linux':
            #  push_cmd('nkf', '-Lu', os.path.join(builder.uproject.engine_root, 'Build/BatchFiles/Linux/GenerateGDBInit.sh'),
                #  '|', 'bash')
            #  push_cmd('nkf', '-Lu', os.path.join(builder.uproject.engine_root, 'Build/BatchFiles/Linux/GenerateProjectFiles.sh'),
                #  '|', 'bash')
            pass
        else:
            self._run_build(target, command, configuration, platform, *args, 
                    defines,
                    opts)

    def cook(self, mapstocook, flavor, opts):
        # recompileshaders changed | global | material | all

        #  Running: C:\dev\bkp\main\Engine\Binaries\Win64\UE4Editor-Cmd.exe C:\dev\bkp\main\BKP\Gargantua.uproject -run=Cook 
        #  -Map=BattleTest_01 
        #  -TargetPlatform=Android_ASTC -fileopenlog -unversioned -compressed 
        #  -abslog=C:\dev\bkp\main\Engine\Programs\AutomationTool\Saved\Cook-2019.01.08-14.11.30.txt 
        #  -stdout -CrashForUAT -unattended -NoLogTimes  -UTF8Output
        targetplatform = None
        platform = self.ctx['platform']
        if platform == 'Windows':
            targetplatform = 'WindowsNoEditor'
        else:
            targetplatform = platform
            if flavor:
                targetplatform += '_' + flavor

        ue4exe = 'UE4Editor-Cmd.exe'
        cmdargs = [
            os.path.join(self.uproject.engine_root, 'Binaries/Win64/{}'.format(ue4exe)),
            self.wpath(self.uproject.uproject_path),
            '-run=Cook', 
            '-NoLogTimes', 
            '-TargetPlatform={}'.format(targetplatform), '-fileopenlog', 
            '-unversioned',
            '-iterate', '-iterateshash',
            #  '-skipeditorcontent', 
            '-abslog={}'.format(self.wpath(os.path.join(self.uproject.project_root, 'Saved/Logs/HelperCook.txt'))), '-stdout',
            '-unattended',  '-UTF8Output',
            '-fullcrashdump']

        if mapstocook:
            cmdargs += [
                '-map={}'.format(mapstocook),
                ]
        self.ctx.run(' '.join(cmdargs), echo=True)

    def _package(self, generate_manifestfile, flavor, *args):
        configuration = self.ctx['configuration']
        platform = self.ctx['platform']
        username = self.ctx.run('cmd.exe /c echo %USERNAME%', hide=True).stdout.strip()

        if self.uproject.has_modules and generate_manifestfile:
            self.ctx.run('cmd-cp932.exe /c ' + ' '.join([
                self.wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/Build.bat')),
                self.uproject.name,
                platform,
                configuration,
                '-Project={}'.format(self.wpath(self.uproject.uproject_path)),
                self.wpath(self.uproject.uproject_path),
                '-NoUBTMakefiles',
                '-remoteini={}'.format(self.wpath(self.uproject.project_root)),
                '-skipdeploy', '-noxge', '-generatemanifest', '-NoHotReload',
                '-fullcrashdump',
                ]), echo=True)
 
        defines = [
                'ALLOW_PROFILEGPU_IN_TEST=1',
                'ENABLE_STATNAMEDEVENTS=UE_BUILD_TEST',
                #  'ENABLE_STATNAMEDEVENTS_UOBJECT=1',
                #  'ALLOW_HITCH_DETECTION=1',
                'USE_LOGGING_IN_SHIPPING=!UE_BUILD_SHIPPING',
                ]
        defines = '-UniqueBuildEnvironment ' + ' '.join(['"-Define:{}"'.format(x) for x in defines])
        defines = ''

        cmdargs = [
            self.wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/RunUAT.bat')),
            '-ScriptsForProject={}'.format(self.wpath(self.uproject.uproject_path)),
            'BuildCookRun',
            '-nocompileeditor',
            '-nop4',
            '-project={}'.format(self.wpath(self.uproject.uproject_path)),
            #  '-SkipCookingEditorContent', 
            *args,
            '-clientconfig={}'.format(configuration), 
            '-prereqs', '-targetplatform={}'.format(platform), '-utf8output',
            '-fullcrashdump',
            defines]

        if platform in ('Android', ):
            # LoadTimeFile
            cmdargs += [
                '-serverconfig={}'.format(configuration),
                '-addcmdline="-statnamedevents -StatCmds=\'unit,fps,dumphitches\' -SessionId={} -SessionOwner=\'{}\' -SessionName=\'{}\' -messaging"'.format(uuid.uuid4().hex, username, self.uproject.name),
                ]

        if configuration in ('Shipping', ):
            cmdargs += ['-nodebuginfo']
        else:
            cmdargs += ['-debuginfo', '-CrashReporter']
            if '-cook' in cmdargs:
                cmdargs.append('-iterativecooking')

        if flavor:
            cmdargs.append('-cookflavor={}'.format(flavor)) 

        self.env['WSLENV'] = 'ADDITIONAL_DEFINITIONS/w'
        self.env['ADDITIONAL_DEFINITIONS'] = 'DISABLE_SMART_BEAT'
        #  self.ctx.run('set')
        self.ctx.run('time cmd.exe /c ' + ' '.join(cmdargs), echo=True)

    def package(self, flavor):
# Parsing command line: -ScriptsForProject=C:/dev/bkp/main/BKP/Gargantua.uproject BuildCookRun -project=C:/dev/bkp/main/BKP/Gargantua.uproject -noP4 -clientconfig=Development -serverconfig=Development -nocompileeditor -ue4exe=UE4Editor-Cmd.exe -utf8output -platform=Android_ASTC -targetplatform=Android -cookflavor=ASTC -build -cook -map= -unversionedcookedcontent -pak -compressed -stage -deploy -cmdline=" -Messaging" -device=Android_ASTC@1PASH3M1FK8113 -addcmdline="-SessionId=7DDA49E04148D77367DBB299BCE4B638 -SessionOwner='gondo' -SessionName='New Profile 0' -messaging" -run -compile
# Running: C:\dev\bkp\main\Engine\Binaries\DotNET\UnrealBuildTool.exe Gargantua Android Development -Project=C:\dev\bkp\main\BKP\Gargantua.uproject  C:\dev\bkp\main\BKP\Gargantua.uproject -NoUBTMakefiles  -remoteini="C:\dev\bkp\main\BKP" -skipdeploy -noxge -generatemanifest -NoHotReload
# Running: C:\dev\bkp\main\Engine\Binaries\DotNET\UnrealBuildTool.exe Gargantua Android Development -Project=C:\dev\bkp\main\BKP\Gargantua.uproject  C:\dev\bkp\main\BKP\Gargantua.uproject -NoUBTMakefiles  -remoteini="C:\dev\bkp\main\BKP" -skipdeploy -noxge -NoHotReload -ignorejunk
# Running: C:\dev\bkp\main\Engine\Binaries\Win64\UnrealPak.exe C:\dev\bkp\main\BKP\Saved\StagedBuilds\Android_ASTC\Gargantua\Content\Paks\Gargantua-Android_ASTC.pak -create=C:\dev\bkp\main\Engine\Programs\AutomationTool\Saved\Logs\PakList_Gargantua-Android_ASTC.txt -encryptionini -enginedir="C:\dev\bkp\main\Engine" -projectdir="C:\dev\bkp\main\BKP" -platform=Android -abslog="C:\dev\bkp\main\Engine\Programs\AutomationTool\Saved\Logs\PakLog_Gargantua-Android_ASTC.log" -order=C:\dev\bkp\main\BKP\Build\Android_ASTC\FileOpenOrder\CookerOpenOrder.log -UTF8Output -multiprocess
        archive_name = '{}_{}_{}'.format(self.ctx['platform'], self.ctx['configuration'], int(time.time()))

        self._package(True, flavor, 
            '-build', '-compile', '-cook', '-stage', '-pak', '-archive', '-package', '-compressed', 
            '-archivedirectory={}'.format(self.wpath(os.path.join(self.uproject.project_root, 'Saved/Packages', archive_name))),
            '-mapsonly')

    def deploy(self, mapstocook, flavor, generate_manifest, full, opts):
        if not mapstocook:
            result = self.select_map()
            selected = result.stdout.strip()
            print("Selected Map: {}".format(selected))
            mapstocook = os.path.basename(selected[:-5])

        targetplatform = self.ctx['platform']
        if flavor:
            targetplatform += '_' + flavor

        addargs = []

        archive_name = '{}_{} ({}) {}'.format(targetplatform, self.ctx['configuration'], 'map={}, params={} {}'.format(mapstocook, opts, ' '.join(addargs)), int(time.time()))
        archive_path = os.path.join(self.uproject.project_root, 'Saved/Archive', archive_name)

        #  if full is False:
            #  addargs.append('-iterativedeploy')
        if not '-cook' in opts:
            addargs.append('-cookonthefly')

        options = addargs + (opts or '').split(' ')

        result = self._package(generate_manifest, flavor, 
            '-deploy', 
            #  '-compile', 
            '-nocompile',
            '-stage', 
            '-pak', 
            #  '-archive', '-archivedirectory=\'{}\''.format(self.wpath(archive_path)),
            '-compressed', 
            '-map={}'.format(mapstocook),
            '-cmdline="{}"'.format(mapstocook.split('+')[0]),
            *options)

        #  if result:
        if True:
            src = os.path.join(self.uproject.project_root, 'Saved/StagedBuilds/{}'.format(targetplatform))
            dest = os.path.join(archive_path, 'StagedBuilds')
            print('move: {} => {}'.format(src, dest))
            shutil.move(src, dest)

            #  external_storage = self.ctx.run('''cmd.exe /c adb.exe shell 'echo $EXTERNAL_STORAGE' ''', hide=True).stdout.strip()
            #  deploy_target = '{}/UE4Game/{}'.format(external_storage, self.uproject.name)
            #  self.ctx.run('cmd.exe /c adb.exe rm -rf \'{}/UE4Game/{}\''.format(external_storage, self.uproject.name))
            #  self.ctx.run('cmd.exe /c adb.exe rm -rf \'{}/obb/{}\''.format(external_storage, self.uproject.name))
            #  self.ctx.run('cmd.exe /c adb.exe rm -rf \'{}/Android/obb/{}\''.format(external_storage, self.uproject.name))
            #  self.ctx.run('cmd.exe /c adb.exe push \'{}\' \'{}\''.format(self.wpath(dest), deploy_target))

    def addcmdline(self, cmdline, use_session, session_name):
        platform = self.ctx['platform']

        def relative_to(base, dst, relative_count=0):
            try:
                path = base.relative_to(dst)
            except ValueError:
                dst = os.path.dirname(dst)
                if dst == '/':
                    raise
                return relative_to(base, dst, relative_count + 1)
            return os.path.join('/'.join(['..'] * relative_count), path)

        uproject_path = '../../../{0}/{0}.uproject'.format(self.uproject.name)

        if platform == 'Android':
            addcmdlines = []
            if use_session:
                username = self.ctx.run('cmd.exe /c echo %USERNAME%', hide=True).stdout.strip()
                addcmdlines.append('''-SessionId={} -SessionOwner='{}' -SessionName='{}' -messaging'''.format( 
                    uuid.uuid4().hex, username, session_name or self.uproject.name))

            cmdline = '''{} {} {}'''.format(
               uproject_path, cmdline, ' '.join(addcmdlines))

            external_storage = self.ctx.run('''cmd.exe /c adb.exe shell 'echo $EXTERNAL_STORAGE' ''', hide=True).stdout.strip()

            self.ctx.run('cmd.exe /c adb.exe shell "echo {} > {}/UE4Game/{}/UE4CommandLine.txt"'.format(
                cmdline, external_storage, self.uproject.name), echo=True)

    def uat(self):
        cmdargs = [
            self.wpath(os.path.join(self.uproject.engine_root, 'Build/BatchFiles/RunUAT.bat')),
            ]
        self.ctx.run('/mnt/c/Windows/System32/cmd.exe /c ' + ' '.join(cmdargs))
