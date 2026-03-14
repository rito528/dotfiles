{ ... }:
{
  home.file.".claude" = {
    source = ../../config/claude;
    recursive = true;
  };

  home.file.".claude/hooks/notify.sh" = {
    source = ../../config/claude/hooks/notify.sh;
    executable = true;
  };
}
