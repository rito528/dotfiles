{ lib, personal, ... }:
{
  programs.git = {
    enable = true;
    signing = {
      format = "openpgp";
    }
    // lib.optionalAttrs (personal.gpgKey != "") {
      key = personal.gpgKey;
      signByDefault = true;
    };
    ignores = [
      ".idea/"
      ".vscode/"
      ".codex"
      ".codex/"
      ".direnv/"
      ".env"
      ".envrc"
      ".env.local"
      ".claude/settings.local.json"
      ".claude/worktrees/"
    ];
    settings = {
      user = {
        name = personal.name;
        email = personal.email;
      };
      gpg.program = "gpg";
      init.defaultBranch = "main";
      core.editor = "nvim";
      "credential \"https://github.com\"".helper = [
        ""
        "!/usr/bin/gh auth git-credential"
      ];
      "credential \"https://gist.github.com\"".helper = [
        ""
        "!/usr/bin/gh auth git-credential"
      ];
      push.autoSetupRemote = true;
      "url \"git@github.com:\"".insteadOf = "https://github.com/";
    };
  };

  xdg.configFile."git/ignore".force = true;
}
