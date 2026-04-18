#!/usr/bin/env bash

REPO="github:rito528/dotfiles"

echo "Fetching templates from $REPO ..."
mapfile -t TEMPLATES < <(nix flake show "$REPO" --json 2>/dev/null | jq -r '.templates | keys[]' | sort)

if [ ${#TEMPLATES[@]} -eq 0 ]; then
  echo "No templates found." >&2
  exit 1
fi

# "local" を末尾に追加
TEMPLATES+=("local")

build_description() {
  local name="$1"
  if [ "$name" = "local" ]; then
    printf "local flake            (use flake)"
  else
    printf "%-30s (%s#%s)" "$name" "$REPO" "$name"
  fi
}

# テンプレートを選択する
if command -v fzf > /dev/null 2>&1; then
  DESCRIPTIONS=()
  for t in "${TEMPLATES[@]}"; do
    DESCRIPTIONS+=("$(build_description "$t")")
  done
  selected=$(printf '%s\n' "${DESCRIPTIONS[@]}" | fzf --prompt="Select template: " --height=15 --reverse)
  [ -z "$selected" ] && { echo "Aborted."; exit 0; }
  for i in "${!DESCRIPTIONS[@]}"; do
    if [ "${DESCRIPTIONS[$i]}" = "$selected" ]; then
      template="${TEMPLATES[$i]}"
      break
    fi
  done
else
  echo "Select template:"
  for i in "${!TEMPLATES[@]}"; do
    echo "  $((i + 1))) $(build_description "${TEMPLATES[$i]}")"
  done
  printf "> "
  read -r choice
  if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#TEMPLATES[@]} ]; then
    echo "Invalid selection." >&2
    exit 1
  fi
  template="${TEMPLATES[$((choice - 1))]}"
fi

if [ "$template" = "local" ]; then
  envrc_content="use flake"
else
  envrc_content="use flake '$REPO#$template'"
fi

# .envrc が既に存在する場合は確認
if [ -f .envrc ]; then
  echo ".envrc already exists:"
  echo "  $(cat .envrc)"
  printf "Overwrite? [y/N] "
  read -r overwrite
  if [ "$overwrite" != "y" ] && [ "$overwrite" != "Y" ]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "$envrc_content" > .envrc
echo "Created .envrc: $envrc_content"

if command -v direnv > /dev/null 2>&1; then
  printf "Run 'direnv allow'? [Y/n] "
  read -r allow
  if [ "$allow" != "n" ] && [ "$allow" != "N" ]; then
    direnv allow
  fi
fi
