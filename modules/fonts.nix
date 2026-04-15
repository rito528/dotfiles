{ pkgs, ... }:
{
  home.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-cjk-serif
    noto-fonts-color-emoji
  ];

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      sansSerif = [
        "Noto Sans CJK JP"
        "Noto Sans"
      ];
      serif = [
        "Noto Serif CJK JP"
        "Noto Serif"
      ];
      emoji = [ "Noto Color Emoji" ];
    };
  };
}
