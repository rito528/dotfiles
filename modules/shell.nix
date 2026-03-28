{ pkgs, ... }:
{
  home.sessionVariables = {
    NIX_BUILD_SHELL = "${pkgs.zsh}/bin/zsh";
    LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib\${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}";
  };

  programs.zsh = {
    enable = true;

    history = {
      ignoreDups = true;
      ignoreSpace = true;
      size = 10000;
      save = 10000;
      share = true;
    };

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
      gpull = "git switch $(git symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||') && git pull";
      dev-rust = "nix develop --refresh 'github:rito528/dotfiles?dir=nix#rust' --command zsh";
      dev-scala = "nix develop --refresh 'github:rito528/dotfiles?dir=nix#scala' --command zsh";
      dev-typescript = "nix develop --refresh 'github:rito528/dotfiles?dir=nix#typescript' --command zsh";
    };

    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.zsh-autosuggestions;
        file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
      }
    ];

    profileExtra = ''
      # Nix daemon
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi
    '';

    initContent = ''
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#888888"
      ZSH_AUTOSUGGEST_STRATEGY=(match_prev_cmd)

      # Nix daemon
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi

      repo() {
        local selected
        local list
        list=$(ghq list; echo "dotfiles")
        if [ -n "$1" ]; then
          selected=$(echo "$list" | grep -i "$1" | head -1)
        else
          selected=$(echo "$list" | fzf --prompt="repo> " --height=40%)
        fi
        if [ -n "$selected" ]; then
          if [ "$selected" = "dotfiles" ]; then
            cd "$HOME/dotfiles" || return
          else
            cd "$(ghq root)/$selected" || return
          fi
        fi
      }
    '';
  };

  programs.dircolors = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
  };

  programs.starship = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = true;
  };
}
