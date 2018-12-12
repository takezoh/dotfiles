from fabric import task
from .build import BuildCommand
from .generator import ProjectGenerator
from .editorsupport import EditorSupport


def _build_task(name):
    @task(name=name, optional=('target', 'configuration', 'platform', 'opts'))
    def inner(c, target=None, configuration='DevelopmentEditor', platform='Win64', opts=()):
        builder = BuildCommand(c, opts=opts)
        builder.build(target, name, configuration, platform)
    return inner


build = _build_task('build')
rebuild = _build_task('rebuild')
clean = _build_task('clean')


@task(optional=('platform', 'opts'))
def cook(c, platform='WindowsNoEditor', opts=None):
    builder = BuildCommand(c, opts=opts)
    builder.cook(platform)


@task(optional=('configuration', 'platform', 'opts'))
def package(c, configuration='Development', platform='Win64', opts=None):
    try:
        platform, flavor = platform.split('_', 1)
    except ValueError:
        platform, flavor = platform, None

    builder = BuildCommand(c, opts=opts)
    builder.package(configuration, platform, flavor)



@task
def projectfiles(c, *args, **kwargs):
    BuildCommand(c)._run_build('UnrealBuildTool', 'Build', 'Development', platform='AnyCPU')
    builder = ProjectGenerator(c, *args, **kwargs)
    builder.manifest_file(*args, **kwargs)
    builder.project_files(*args, **kwargs)


@task
def supportfiles(c, *args, **kwargs):
    builder = ProjectGenerator(c, *args, **kwargs)
    builder.support_files(*args, **kwargs)



@task(optional=('which', 'opts'))
def editor(c, which=None, opts=None):
    support = EditorSupport(c, opts=opts)
    if which:
        print(getattr(support.uproject, which.replace('-', '_')))
        return

    support.launch()


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
