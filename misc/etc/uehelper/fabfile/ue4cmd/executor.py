import invoke
import fabric
from invoke.util import six
from invoke.parser import ParserContext

import os

ENV = {
    'PATH': '{}/bin:/usr/bin:/bin'.format(os.path.join(os.path.dirname(__file__), '..')),
}


class Context(invoke.Context):
    def run(self, cmd, *args, **kwargs):
        cmd = cmd.lstrip().replace('/mnt/c/Windows/System32/cmd.exe', 'cmd.exe')
        if cmd.startswith('cmd-cp932.exe'):
            kwargs['encoding'] = 'cp932'
        kwargs['env'] = ENV
        return super().run(cmd, *args, **kwargs)


class Call(invoke.Call):
    def make_context(self, config):
        return Context(config=config)


class Executor(fabric.Executor):
    def normalize(self, tasks):
        """
        Transform arbitrary task list w/ various types, into `.Call` objects.

        See docstring for `~.Executor.execute` for details.

        .. versionadded:: 1.0
        """
        calls = []
        for task in tasks:
            name, kwargs = None, {}
            if isinstance(task, six.string_types):
                name = task
            elif isinstance(task, ParserContext):
                name = task.name
                kwargs = task.as_kwargs
            else:
                name, kwargs = task
            c = Call(task=self.collection[name], kwargs=kwargs, called_as=name)
            calls.append(c)
        if not tasks and self.collection.default is not None:
            calls = [Call(task=self.collection[self.collection.default])]
        return calls