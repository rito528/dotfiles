{ ... }:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
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
