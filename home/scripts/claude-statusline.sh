# Claude Code status line mirroring the starship prompt; SL_* colours come from theme/tokens.nix. Reads the session JSON on stdin.
input=$(cat)
cwd=$(jq -r '.workspace.current_dir // .cwd' <<<"$input")
model=$(jq -r '.model.display_name // empty' <<<"$input")
used=$(jq -r '.context_window.used_percentage // empty' <<<"$input")

c() { printf '\033[1;38;2;%sm' "$1"; }
r=$'\033[0m'
accent=$SL_ACCENT blue=$SL_BLUE green=$SL_GREEN
red=$SL_RED yellow=$SL_YELLOW aqua=$SL_AQUA

g() { git -C "$cwd" --no-optional-locks "$@" 2>/dev/null; }

root=$(g rev-parse --show-toplevel || true)
if [[ -n $root ]]; then
  dir="$(basename "$root")${cwd#"$root"}"
else
  dir="${cwd/#$HOME/\~}"
  IFS=/ read -ra parts <<<"$dir"
  if ((${#parts[@]} > 3)); then
    dir=$(
      IFS=/
      echo "${parts[*]: -3}"
    )
  fi
fi
out="$(c "$accent")${dir}${r}"

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

# Kubernetes context; red when the name looks like prod.
kcfg="${KUBECONFIG:-$HOME/.kube/config}"
kctx=""
[[ -r ${kcfg%%:*} ]] && kctx=$(awk '$1 == "current-context:" { print $2; exit }' "${kcfg%%:*}")
if [[ -n $kctx ]]; then
  kcol=$aqua
  grep -qiE '(^|[-_./])prod(uction)?([-_./]|$)' <<<"$kctx" && kcol=$red
  out+=" $(c "$kcol")k8s:${kctx}${r}"
fi

[[ -n ${IN_NIX_SHELL:-} ]] && out+=" $(c "$aqua")(nix ${IN_NIX_SHELL})${r}"
[[ -n $model ]] && out+=" $(c "$yellow")${model}${r}"
[[ -n $used ]] && out+=" $(c "$blue")ctx $(printf '%.0f' "$used")%${r}"

printf '%s\n' "$out"
