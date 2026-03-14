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
      delete-branches = "git fetch -p && git branch --merged | grep -v '*' | xargs git branch -d";
    };

    sessionVariables = {
      PNPM_HOME = "$HOME/.local/share/pnpm";
    };

    initExtra = ''
      # debian chroot
      if [ -z "''${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
          debian_chroot=$(cat /etc/debian_chroot)
      fi

      # color prompt (starship が上書きするが互換性のため残す)
      case "$TERM" in
          xterm-color|*-256color) color_prompt=yes;;
      esac
      if [ -n "$debian_chroot" ]; then
          _chroot_prefix="($debian_chroot)"
      else
          _chroot_prefix=""
      fi
      if [ "$color_prompt" = yes ]; then
          PS1="$_chroot_prefix\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
      else
          PS1="$_chroot_prefix\u@\h:\w\$ "
      fi
      unset color_prompt force_color_prompt _chroot_prefix
      case "$TERM" in
      xterm*|rxvt*)
          PS1="\[\e]0;$debian_chroot\u@\h: \w\a\]$PS1"
          ;;
      esac

      # dircolors
      if [ -x /usr/bin/dircolors ]; then
          test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
      fi

      # bash completion
      if ! shopt -oq posix; then
        if [ -f /usr/share/bash-completion/bash_completion ]; then
          . /usr/share/bash-completion/bash_completion
        elif [ -f /etc/bash_completion ]; then
          . /etc/bash_completion
        fi
      fi

      # switch-branch-with-refresh: 誤って現在のブランチにコミットした際、
      # そのコミットを新しいブランチに移動し、元のブランチをリモートの状態にリセットする
      # 使い方: switch-branch-with-refresh <新ブランチ名>
      switch-branch-with-refresh() {
        if [ -z "$1" ]; then
          echo "Usage: switch-branch-with-refresh <new-branch-name>" >&2
          return 1
        fi

        local current_branch
        current_branch=$(git branch --show-current)

        if [ -z "$current_branch" ]; then
          echo "Error: Not on a branch (detached HEAD?)" >&2
          return 1
        fi

        # 新ブランチを作成（現在のコミットをそのまま引き継ぐ）
        if ! git switch -c "$1"; then
          echo "Error: Failed to create branch '$1'." >&2
          return 1
        fi

        # 元ブランチをリモートの状態にリセット
        git fetch origin
        git switch "$current_branch"
        echo "Warning: This will reset '$current_branch' to origin/$current_branch with --hard."
        read -r -p "Continue? [y/N] " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
          echo "Aborted. Switching back to '$1'."
          git switch "$1"
          return 1
        fi
        git reset --hard "origin/$current_branch"

        # 新ブランチに移動して完了
        git switch "$1"
        echo "Done. Commits are on '$1'. '$current_branch' reset to origin/$current_branch."
      }

      # GPG
      export GPG_TTY=$(tty)

      # PATH additions
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac
      export PATH="$HOME/.opencode/bin:$PATH"

      # direnv
      command -v direnv &>/dev/null && eval "$(direnv hook bash)"

      # cargo
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
      [ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

      # Nix daemon
      if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
          . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
      fi

      # starship
      command -v starship &>/dev/null && eval "$(starship init bash)"
    '';
  };
}
