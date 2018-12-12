"""
CLI entrypoint & parser configuration.

Builds on top of Invoke's core functionality for same.
"""
from invoke import Argument
from fabric import __version__ as fabversion
from fabric.main import Fab

from .executor import Executor
from .config import Config

version = "1.0"


class UE(Fab):
    def print_version(self):
        super().print_version()
        print("Fabric {}".format(fabversion))

    def core_args(self):
        core_args = super().core_args()
        my_args = [
            Argument(
                names=("P", "platform"),
                help="",
            ),
            Argument(
                names=("C", "configuration"),
                help="",
            ),
            Argument(
                names=("T", "type"),
                help="",
            ),
        ]
        return core_args + my_args

    def update_config(self):
        super().update_config()
        for name in ('platform', 'configuration', 'type'):
            if self.args[name].value:
                self.config[name] = self.args[name].value

program = UE(
    name="UE", version=version, executor_class=Executor, config_class=Config
)
