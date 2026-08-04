{ pkgs, ... }:
{
  # 既定の linkApps は .app を /nix/store への symlink として置くだけで、Spotlight は
  # symlink 先を辿らないため Ghostty.app がインデックスされない。実体コピーに切り替えて
  # Spotlight と Launchpad から起動できるようにする。両者は同じ
  # ~/Applications/Home Manager Apps/ を使うため linkApps は無効にする。
  targets.darwin.linkApps.enable = false;
  targets.darwin.copyApps.enable = true;

  # macOS 標準ターミナルの代替。キーバインドは普段使いの Windows Terminal に合わせる。
  programs.ghostty = {
    enable = true;
    # pkgs.ghostty は Linux 専用のため、Mac では公式 dmg を再パッケージした ghostty-bin を使う。
    package = pkgs.ghostty-bin;

    settings = {
      # これを有効にしないと Option が特殊文字入力に使われ、alt+... のバインドが効かない。
      macos-option-as-alt = true;

      # 既定の cmd 系バインドは残し、Windows Terminal 相当のバインドを上乗せする。
      # キー名は Ghostty の物理キー名(digit_1, arrow_left など)で指定する。
      keybind = [
        # タブ
        "ctrl+shift+t=new_tab"
        "ctrl+shift+n=new_window"
        # Windows Terminal の Ctrl+Shift+W は分割中ならペインを閉じるため close_surface を割り当てる。
        "ctrl+shift+w=close_surface"
        "ctrl+tab=next_tab"
        "ctrl+shift+tab=previous_tab"
        "ctrl+alt+digit_1=goto_tab:1"
        "ctrl+alt+digit_2=goto_tab:2"
        "ctrl+alt+digit_3=goto_tab:3"
        "ctrl+alt+digit_4=goto_tab:4"
        "ctrl+alt+digit_5=goto_tab:5"
        "ctrl+alt+digit_6=goto_tab:6"
        "ctrl+alt+digit_7=goto_tab:7"
        "ctrl+alt+digit_8=goto_tab:8"
        "ctrl+alt+digit_9=last_tab"

        # 分割(Windows Terminal の Alt+Shift++ / Alt+Shift+- / Alt+Shift+D)
        "alt+shift+equal=new_split:right"
        "alt+shift+minus=new_split:down"
        "alt+shift+d=new_split:auto"

        # ペイン間の移動
        "alt+arrow_left=goto_split:left"
        "alt+arrow_right=goto_split:right"
        "alt+arrow_up=goto_split:up"
        "alt+arrow_down=goto_split:down"

        # ペインのリサイズ
        "alt+shift+arrow_left=resize_split:left,10"
        "alt+shift+arrow_right=resize_split:right,10"
        "alt+shift+arrow_up=resize_split:up,10"
        "alt+shift+arrow_down=resize_split:down,10"

        # クリップボード
        "ctrl+shift+c=copy_to_clipboard"
        "ctrl+shift+v=paste_from_clipboard"

        # フォントサイズ
        "ctrl+equal=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+digit_0=reset_font_size"
      ];
    };
  };
}
