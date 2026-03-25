{ ... }:
{
  home.file.".claude/settings.json".source = ../../config/claude/settings.json;

  home.file.".claude/skills" = {
    source = ../../config/claude/skills;
    recursive = true;
  };

  home.file.".claude/hooks/notify.sh" = {
    text = builtins.readFile ../../config/claude/hooks/notify.sh;
    executable = true;
  };

  home.file.".claude/statusline.py" = {
    text = builtins.readFile ../../config/claude/statusline.py;
    executable = true;
  };
}
