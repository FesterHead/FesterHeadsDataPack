#!/usr/bin/env bash
# release.sh - interactive helper to create and push a release or draft tag
# Usage: run from repository root on Linux/WSL (Ubuntu 24.04)

set -u

die() {
  echo "Error: $*" >&2
  exit 1
}

info() {
  echo "[INFO $(date '+%Y-%m-%d %H:%M:%S')] $*"
}

get_latest_tag() {
  git describe --tags --abbrev=0 2>/dev/null || true
}

# ensure git available and we're in a repo
if ! command -v git >/dev/null 2>&1; then
  die "git is not installed or not on PATH"
fi
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  die "not inside a git repository"
fi

latest=$(get_latest_tag)
if [ -z "$latest" ]; then
  info "Latest tag: none"
else
  info "Latest tag: $latest"
fi

suggest=""
if [ -n "$latest" ]; then
  if [[ $latest == vdraft-* ]]; then
    suggest=${latest#vdraft-}
  elif [[ $latest == v* ]]; then
    suggest=${latest#v}
  fi
fi

if [ -n "$suggest" ]; then
  info "Suggested version: $suggest"
fi

read -r -p "Release type - (r)elease or (d)raft? [r/d] " choice
choice=${choice:-r}
case "$choice" in
  r|R) mode="release" ;;
  d|D) mode="draft" ;;
  *) die "Invalid choice" ;;
esac

defaultPrompt="[no default]"
if [ -n "$suggest" ]; then defaultPrompt="[default: $suggest]"; fi
read -r -p "Version (e.g. 1.2.3) $defaultPrompt " version
version=${version:-$suggest}
if [ -z "$version" ]; then
  die "No version provided. Exiting."
fi

# simple semver check X.Y.Z
if ! [[ $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Warning: Version does not match X.Y.Z pattern. Proceeding anyway."
  read -r -p "Continue with version '$version'? [y/N] " ok
  case "$ok" in
    y|Y) ;;
    *) echo 'Aborted.'; exit 1 ;;
  esac
fi

if [ "$mode" = "release" ]; then
  tag="v$version"
else
  tag="vdraft-$version"
fi

info "Creating tag: $tag"

# check existing tag
if git rev-parse --verify "refs/tags/$tag" >/dev/null 2>&1; then
  read -r -p "Tag $tag already exists. Overwrite (delete & recreate)? [y/N] " overwrite
  case "$overwrite" in
    y|Y)
      info "Deleting local tag $tag..."
      git tag -d "$tag" >/dev/null 2>&1 || true
      info "Deleting remote tag $tag (if present)..."
      git push --delete origin "$tag" >/dev/null 2>&1 || true
      # fallback ref syntax
      git push origin ":refs/tags/$tag" >/dev/null 2>&1 || true
      ;;
    *) echo 'Aborted.'; exit 1 ;;
  esac
fi

info "Creating annotated tag $tag..."
if ! git tag -a "$tag" -m "Release $tag"; then
  die "git tag failed"
fi

info "Pushing tag to origin..."
if ! git push origin "$tag"; then
  die "git push failed"
fi

info "Done. The GitHub Actions release workflow will run on the pushed tag."
info "Pau. Have a great day! 🏄 🌈 🌴 🌺 🦄"
