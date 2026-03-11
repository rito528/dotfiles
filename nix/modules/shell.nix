{ ... }:
{
  home.file.".bashrc" = {
    source = ../../config/bashrc;
    force = true;
  };
  home.file.".bash_profile".source = ../../config/bash_profile;
}
