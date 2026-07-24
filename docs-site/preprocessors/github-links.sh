#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "supports" ]]; then
  exit 0
fi

repo_url="https://github.com/rito528/dotfiles"

jq --arg repo "$repo_url" '
  def normalize_path:
    split("/")
    | reduce .[] as $seg ([];
        if ($seg == "" or $seg == ".") then .
        elif $seg == ".." then (if length > 0 then .[:-1] else . end)
        else . + [$seg] end)
    | join("/");

  def fix_content($chapter_path):
    ($chapter_path | if test("/") then sub("/[^/]*$"; "") else "" end) as $reldir
    | (if $reldir == "" then "docs-site/src" else "docs-site/src/" + $reldir end) as $basedir
    | gsub(
        "\\]\\((?<target>\\.\\./[^)]+)\\)";
        ($basedir + "/" + .target | normalize_path) as $abs
        | (if (.target | endswith("/")) then "tree" else "blob" end) as $kind
        | "](" + $repo + "/" + $kind + "/main/" + $abs + ")"
      );

  def walk_item:
    if (type == "object") and has("Chapter") then
      (.Chapter.path) as $p
      | (if $p != null then .Chapter.content |= fix_content($p) else . end)
      | .Chapter.sub_items |= map(walk_item)
    else . end;

  (.[1].items |= map(walk_item)) | .[1]
'
