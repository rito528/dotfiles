{ ... }:
{
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

  home.file.".config/git/hooks/pre-commit" = {
    source = ../../config/git/hooks/pre-commit;
    executable = true;
  };

  xdg.configFile."git/ignore".force = true;
}
