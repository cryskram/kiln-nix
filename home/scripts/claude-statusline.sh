# Claude Code status line mirroring the starship prompt (Gruvbox). Reads the session JSON on stdin.
input=$(cat)
cwd=$(jq -r '.workspace.current_dir // .cwd' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")
used=$(jq -r '.context_window.used_percentage // empty' <<<"$input")

c() { printf '\033[1;38;2;%sm' "$1"; }
r=$'\033[0m'
orange="254;128;25" blue="131;165;152" green="184;187;38"
red="251;73;52" yellow="250;189;47" aqua="142;192;124"

g() { git -C "$cwd" --no-optional-locks "$@" 2>/dev/null; }

root=$(g rev-parse --show-toplevel || true)
if [[ -n $root ]]; then
  dir="$(basename "$root")${cwd#"$root"}"
else
  dir="${cwd/#$HOME/\~}"
  IFS=/ read -ra parts <<<"$dir"
  if ((${#parts[@]} > 3)); then
    dir=$(IFS=/; echo "${parts[*]: -3}")
  fi
fi
out="$(c "$orange")${dir}${r}"

if [[ -n $root ]]; then
  branch=$(g branch --show-current || true)
  [[ -z $branch ]] && branch=$(g rev-parse --short HEAD || true)
  out+=" $(c "$blue")(${branch})${r}"

  st=$(g status --porcelain || true)
  flags=""
  grep -q '^[MADRC]' <<<"$st" && flags+="+"
  grep -q '^.[MT]' <<<"$st" && flags+="!"
  grep -q '^\(.D\|D\)' <<<"$st" && flags+="✘"
  grep -q '^R' <<<"$st" && flags+="»"
  grep -q '^??' <<<"$st" && flags+="?"
  [[ -n $flags ]] && out+=" $(c "$yellow")[${flags}]${r}"

  read -r add del < <(g diff HEAD --numstat | awk '{a+=$1;d+=$2} END{print a+0, d+0}')
  ((add > 0)) && out+=" $(c "$green")+${add}${r}"
  ((del > 0)) && out+=" $(c "$red")-${del}${r}"
fi

[[ -n ${IN_NIX_SHELL:-} ]] && out+=" $(c "$aqua")(nix ${IN_NIX_SHELL})${r}"
[[ -n $model ]] && out+=" $(c "$yellow")${model}${r}"
[[ -n $used ]] && out+=" $(c "$blue")ctx $(printf '%.0f' "$used")%${r}"

printf '%s\n' "$out"
