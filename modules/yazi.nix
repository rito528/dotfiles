{ ... }:
{
  programs.yazi = {
    enable = true;
    settings = {
      mgr.show_hidden = true;
      opener.edit = [
        {
          run = "nvim %s";
          block = true;
          for = "unix";
        }
      ];
    };
  };
}
