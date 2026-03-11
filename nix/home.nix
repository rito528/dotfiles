{ pkgs, lib, ... }:
{
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    jq
    direnv
    starship
    nixfmt-rfc-style
    doppler
    gh
    ripgrep
    nodejs_22
  ];

  home.sessionPath = [ "$HOME/.npm-global/bin" ];

  home.activation.installSecretlint = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! test -f "$HOME/.npm-global/bin/secretlint"; then
      $DRY_RUN_CMD ${pkgs.nodejs_22}/bin/npm install \
        --prefix "$HOME/.npm-global" \
        secretlint \
        @secretlint/secretlint-rule-preset-recommend
    fi
  '';

  programs.gpg.enable = true;

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    extraConfig = "allow-loopback-pinentry";
  };

  programs.git = {
    enable = true;
    signing = {
      key = "F4022307254812F8";
      signByDefault = true;
    };
    ignores = [
      ".idea/"
      ".vscode/"
      ".env"
      ".env.local"
    ];
    settings = {
      user = {
        name = "rito528";
        email = "39003544+rito528@users.noreply.github.com";
      };
      gpg.program = "gpg";
      init.defaultBranch = "main";
      core = {
        editor = "vim";
        hooksPath = "~/.config/git/hooks";
      };
      "credential \"https://github.com\"".helper = [
        ""
        "!/usr/bin/gh auth git-credential"
      ];
      "credential \"https://gist.github.com\"".helper = [
        ""
        "!/usr/bin/gh auth git-credential"
      ];
      push.autoSetupRemote = true;
    };
  };

  home.file.".bashrc" = {
    source = ../config/bashrc;
    force = true;
  };
  home.file.".bash_profile".source = ../config/bash_profile;

  home.file.".config/Code/User/settings.json".source = ../config/vscode/settings.json;

  home.file.".config/git/hooks/pre-commit" = {
    source = ../config/git/hooks/pre-commit;
    executable = true;
  };

  home.file.".secretlintrc.json".source = ../config/secretlintrc.json;

  home.file.".claude" = {
    source = ../config/claude;
    recursive = true;
  };

  xdg.configFile."git/ignore".force = true;

  programs.home-manager.enable = true;
}
