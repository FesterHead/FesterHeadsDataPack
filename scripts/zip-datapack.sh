#!/usr/bin/env bash
# zip-datapack.sh
# Create a single ZIP artifact for releases (bash equivalent of zip-datapack.ps1)

set -euo pipefail
IFS=$'\n\t'

prog=$(basename "$0")
info() {
  echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $*"
}
err() {
  echo "[ERROR $(date '+%Y-%m-%d %H:%M:%S')] $*" >&2
}
die() {
  err "$*"
  exit 1
}

usage(){
  cat <<EOF
Usage: $prog [version] [options]

Options:
  -n, --dry-run               Show what would be done and exit
  -h, --help                  Show this help

Examples:
  $prog                # interactive (suggests latest tag)
  $prog 1.0.18         # provide explicit version
  $prog 1.0.18 -M 1.20.1
EOF
}

read_properties(){
  local path="$1"
  declare -A props
  if [ ! -f "$path" ]; then
    echo ""
    return
  fi
  while IFS='=' read -r key val; do
    key=${key%%"#"*}
    key=$(echo "$key" | awk '{gsub(/^[ \t]+|[ \t]+$/,"",$0); print $0}')
    val=$(echo "${val:-}" | awk '{gsub(/^[ \t]+|[ \t]+$/,"",$0); print $0}')
    if [ -n "$key" ]; then
      props["$key"]="$val"
    fi
  done < "$path"
  # print as key=value lines
  for k in "${!props[@]}"; do
    printf '%s=%s\n' "$k" "${props[$k]}"
  done
}

suggest_version_from_git(){
  if ! command -v git >/dev/null 2>&1; then
    return
  fi
  local tag
  tag=$(git describe --tags --abbrev=0 2>/dev/null || true)
  if [ -z "$tag" ]; then
    return
  fi
  tag=$(echo "$tag" | tr -d '\r' | sed -E 's/^vdraft-//; s/^v//')
  printf '%s' "$tag"
}

# parse args
DRYRUN=0
POSITIONAL=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run|--dryrun) DRYRUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    --) shift; break ;;
    -* ) err "Unknown option: $1"; usage; exit 2 ;;
    * ) POSITIONAL+=("$1"); shift ;;
  esac
done
set -- "${POSITIONAL[@]:-}"

VERSION="${1:-}"

repo_root=$(pwd)
props_raw=$(read_properties "$repo_root/versioning.properties" || true)
base=""
minecraft_version=""
if [ -n "$props_raw" ]; then
  while IFS='=' read -r k v; do
    case "$k" in
      base) base="$v" ;;
      minecraft-version) minecraft_version="$v" ;;
    esac
  done <<<"$props_raw"
fi

[ -z "$base" ] && die "Missing 'base' in versioning.properties"
[ -z "$minecraft_version" ] && die "Missing 'minecraft-version' in versioning.properties"

# Sanitize values read from files or git (remove CR/LF and characters
# that are not safe in filenames/artifact names on Windows/NTFS).
sanitize_name() {
  # remove CR/LF, remove characters: " : < > | * ? \\ / and condense whitespace to '-'
  printf '%s' "$1" | tr -d '\r\n' | sed -E 's/["\:\<\>\|\*\?\\\/]//g' | sed -E 's/[[:space:]]+/-/g'
}

base=$(sanitize_name "$base")
minecraft_version=$(sanitize_name "$minecraft_version")

if [ -z "$VERSION" ]; then
  suggest=$(suggest_version_from_git || true)
  if [ -n "$suggest" ]; then
    info "Suggested version: $suggest"
  fi
  # read from user
  printf 'Version (e.g. 1.2.3) [default: %s]: ' "$suggest"
  read -r userv || true
  if [ -z "$userv" ]; then
    VERSION="$suggest"
  else
    VERSION="$userv"
  fi
  if [ -z "$VERSION" ]; then
    die "No version supplied. Exiting."
  fi
fi

# strip leading v/draft- if present
VERSION=$(echo "$VERSION" | sed -E 's/^vdraft-//; s/^v//')

# sanitize version string
VERSION=$(sanitize_name "$VERSION")

if [ -n "$minecraft_version" ]; then
  zipname="${base}-${minecraft_version}-${VERSION}.zip"
else
  zipname="${base}-${VERSION}.zip"
fi
releases_dir="$repo_root/releases"
mkdir -p "$releases_dir"
zippath="$releases_dir/$zipname"

# Clean up any existing release files that contain invalid characters
# (for example CR/LF) which can break artifact upload on Windows/Actions.
while IFS= read -r f; do
  bn=$(basename "$f")
  # detect carriage return in filename (common when CRLF slipped in)
  case "$bn" in
    *$'\r'*|*$'\n'*)
      info "Removing existing invalid filename: $f"
      rm -f "$f" || die "Unable to remove $f"
      ;;
  esac
done < <(find "$releases_dir" -maxdepth 1 -type f || true)

# If a sanitized target already exists, remove it so we create a fresh file.
if [ -f "$zippath" ]; then
  info "Zip $zippath already exists — overwriting"
  rm -f "$zippath" || die "Unable to remove existing $zippath"
fi

staging="$repo_root/pack_build"
# shellcheck disable=SC2317
# cleanup() is invoked indirectly by the EXIT trap; ShellCheck reports
# SC2317 (unreachable) here as a false positive. Disable the check for this block.
cleanup(){
  if [ -d "$staging" ]; then
    rm -rf "$staging"
  fi
}
trap cleanup EXIT

info "Creating staging area..."
rm -rf "$staging"
mkdir -p "$staging"

info "Copying datapack files into staging..."
cp -a "$repo_root/data-pack-files/." "$staging/"

for f in changelog.md LICENSE README.md; do
  src="$repo_root/$f"
  if [ -e "$src" ]; then
    cp -a "$src" "$staging/"
  fi
done

if [ $DRYRUN -eq 1 ]; then
  info "Dry run: would create $zippath (staging: $staging)"
  exit 0
fi

# Require 'zip' and keep behavior simple
if command -v zip >/dev/null 2>&1; then
  info "Using zip (native)"
  pushd "$staging" >/dev/null
  # Create zip into a temporary file and then atomically move into releases
  tmpzip=$(mktemp -p "$releases_dir" tmp-zip-XXXXXX.zip)
  # ensure zip creates the archive (remove the empty temp file created by mktemp)
  rm -f "$tmpzip"
  if ! zip -r -9 -q "$tmpzip" ./*; then
    rm -f "$tmpzip" || true
    die "zip failed to create archive"
  fi
  popd >/dev/null
  # move to the final name (atomic on POSIX filesystems)
  mv -f "$tmpzip" "$zippath" || die "Failed to move archive to $zippath"
fi

if [ ! -f "$zippath" ]; then
  die "Failed to create $zippath"
fi

sizekib=$(awk "BEGIN {printf \"%.2f\", $(stat -c%s "$zippath")/1024}")
info "Created $zippath (${sizekib} KB)"

# cleanup done by trap
info "Pau. Have a great day! 🏄 🌈 🌴 🌺 🦄"
exit 0
