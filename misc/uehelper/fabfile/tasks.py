from fabric import task
from .build import BuildCommand
from .generator import ProjectGenerator
from .editorsupport import EditorSupport


def _build_task(name):
    @task(name=name)
    def inner(c, target=None, opts=None):
        builder = BuildCommand(c)
        builder.build(target, name, opts or '')
    return inner


build = _build_task('build')
rebuild = _build_task('rebuild')
clean = _build_task('clean')


@task
def cook(c, map=None, flavor=None, opts=None):
    builder = BuildCommand(c)
    builder.cook(map, flavor, opts)


@task
def package(c, flavor=None, opts=None):
    builder = BuildCommand(c)
    builder.package(flavor)


@task
def deploy(c, map=None, flavor=None, manifest=False, full=False, opts=None):
    builder = BuildCommand(c)
    builder.deploy(map, flavor, manifest, full, opts)


@task
def addcmdline(c, cmdline='', session=False, session_name=None):
    builder = BuildCommand(c)
    builder.addcmdline(cmdline, session, session_name)


@task
def projectfiles(c, *args, **kwargs):
    BuildCommand(c)._run_build('UnrealBuildTool', 'Build', 'Development', platform='AnyCPU')
    builder = ProjectGenerator(c, *args, **kwargs)
    builder.project_files(*args, **kwargs)
    builder.manifest_file(*args, **kwargs)


@task
def supportfiles(c, *args, **kwargs):
    builder = ProjectGenerator(c, *args, **kwargs)
    builder.support_files(*args, **kwargs)



@task
def editor(c, which=None, opts=None):
    support = EditorSupport(c)
    if which:
        print(getattr(support.uproject, which.replace('-', '_')))
        return

    support.launch('', opts or '')


@task
def update(c, *args, **kwargs):
    import os
    builder = ProjectGenerator(c, *args, **kwargs)
    c.run(os.path.join(builder.uproject.engine_root, 'Binaries/DotNET/GitDependencies.exe'))
    #  c.run(os.path.join(builder.uproject.engine_root, 'Extras/Redist/en-us/UE4PrereqSetup_x64.exe'))
    #
@task
def test(c):
    print (type(c))
    print(dir(c))
    print(c['platform'])
    print(c.config)
