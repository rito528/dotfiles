{ ... }:
{
  programs.bash = {
    enable = true;

    historyControl = [ "ignoreboth" ];
    historySize = 1000;
    historyFileSize = 2000;

    shellOptions = [
      "histappend"
      "checkwinsize"
    ];

    shellAliases = {
      ls = "ls --color=auto";
      ll = "ls -alF";
      la = "ls -A";
      l = "ls -CF";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";
      alert = ''notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e 's/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//')"'';
      delete-branches = "git fetch -p && git branch --merged | grep -v '*' | xargs -r git branch -d";
      dev-rust = "nix develop --refresh github:rito528/dotfiles?dir=nix#rust";
      dev-scala = "nix develop --refresh github:rito528/dotfiles?dir=nix#scala";
      dev-typescript = "nix develop --refresh github:rito528/dotfiles?dir=nix#typescript";
    };

    initExtra = ''
      # debian chroot
      if [ -z "''${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
          debian_chroot=$(cat /etc/debian_chroot)
      fi

      # bash completion (system-provided)
      if ! shopt -oq posix; then
        if [ -f /usr/share/bash-completion/bash_completion ]; then
          . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
          . /etc/bash_completion
        fi
      fi

      # Nix daemon
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '';
  };

  programs.dircolors = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };
}
