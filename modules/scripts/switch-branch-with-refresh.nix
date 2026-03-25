{ pkgs, ... }:
{
  home.packages = [
    (pkgs.writeShellApplication {
      name = "switch-branch-with-refresh";
      runtimeInputs = [ pkgs.git ];
      text = ''
        if [ -z "''${1:-}" ]; then
          echo "Usage: switch-branch-with-refresh <new-branch-name>" >&2
          exit 1
        fi

        current_branch=$(git branch --show-current)

        if [ -z "$current_branch" ]; then
          echo "Error: Not on a branch (detached HEAD?)" >&2
          exit 1
        fi

        # 新ブランチを作成（現在のコミットをそのまま引き継ぐ）
        if ! git switch -c "$1"; then
          echo "Error: Failed to create branch '$1'." >&2
          exit 1
        fi

        # 元ブランチをリモートの状態にリセット
        git fetch origin
        git switch "$current_branch"
        echo "Warning: This will reset '$current_branch' to origin/$current_branch with --hard."
        read -r -p "Continue? [y/N] " confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
          echo "Aborted. Switching back to '$1'."
          git switch "$1"
          exit 1
        fi
        git reset --hard "origin/$current_branch"

        # 新ブランチに移動して完了
        git switch "$1"
        echo "Done. Commits are on '$1'. '$current_branch' reset to origin/$current_branch."
      '';
    })
  ];
}
