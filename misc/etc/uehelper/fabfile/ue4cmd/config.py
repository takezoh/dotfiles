from fabric import Config as FabConfig
from invoke.config import merge_dicts

class Config(FabConfig):
#    def __init__(self, *args, **kwargs):
#        """
#        Creates a new Fabric-specific config object.
#
#        For most API details, see `invoke.config.Config.__init__`. Parameters
#        new to this subclass are listed below.
#
#        :param ssh_config:
#            Custom/explicit `paramiko.config.SSHConfig` object. If given,
#            prevents loading of any SSH config files. Default: ``None``.
#
#        :param str runtime_ssh_path:
#            Runtime SSH config path to load. Prevents loading of system/user
#            files if given. Default: ``None``.
#
#        :param str system_ssh_path:
#            Location of the system-level SSH config file. Default:
#            ``/etc/ssh/ssh_config``.
#
#        :param str user_ssh_path:
#            Location of the user-level SSH config file. Default:
#            ``~/.ssh/config``.
#
#        :param bool lazy:
#            Has the same meaning as the parent class' ``lazy``, but
#            additionally controls whether SSH config file loading is deferred
#            (requires manually calling `load_ssh_config` sometime.) For
#            example, one may need to wait for user input before calling
#            `set_runtime_ssh_path`, which will inform exactly what
#            `load_ssh_config` does.
#        """
#        # Tease out our own kwargs.
#        # TODO: consider moving more stuff out of __init__ and into methods so
#        # there's less of this sort of splat-args + pop thing? Eh.
#        ssh_config = kwargs.pop("ssh_config", None)
#        lazy = kwargs.get("lazy", False)
#        self.set_runtime_ssh_path(kwargs.pop("runtime_ssh_path", None))
#        system_path = kwargs.pop("system_ssh_path", "/etc/ssh/ssh_config")
#        self._set(_system_ssh_path=system_path)
#        self._set(_user_ssh_path=kwargs.pop("user_ssh_path", "~/.ssh/config"))
#
#        # Record whether we were given an explicit object (so other steps know
#        # whether to bother loading from disk or not)
#        # This needs doing before super __init__ as that calls our post_init
#        explicit = ssh_config is not None
#        self._set(_given_explicit_object=explicit)
#
#        # Arrive at some non-None SSHConfig object (upon which to run .parse()
#        # later, in _load_ssh_file())
#        if ssh_config is None:
#            ssh_config = SSHConfig()
#        self._set(base_ssh_config=ssh_config)
#
#        # Now that our own attributes have been prepared & kwargs yanked, we
#        # can fall up into parent __init__()
#        super(Config, self).__init__(*args, **kwargs)
#
#        # And finally perform convenience non-lazy bits if needed
#        if not lazy:
#            self.load_ssh_config()

    @staticmethod
    def global_defaults():
        defaults = FabConfig.global_defaults()
        ours = {
            'platform': 'Win64',
            'configuration': 'Development',
            'type': 'Editor',
        }
        merge_dicts(defaults, ours)
        return defaults
