{ pkgs, lib, ... }:
{
  home.file.".secretlintrc.json".text = builtins.toJSON {
    rules = [
      { id = "@secretlint/secretlint-rule-preset-recommend"; }
    ];
  };
}
