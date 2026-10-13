#!/usr/bin/env bash
# Clone the benchmark targets at the versions the ground truth in examples/gt/ was
# annotated against, and apply the lab patches. Safe to re-run.
set -euo pipefail

cd "$(dirname "$0")"
mkdir -p src

# name | repo | pinned commit | sparse path (optional) | patch
TARGETS=(
  "vuln-bank|https://github.com/Commando-X/vuln-bank.git|b1962823||vuln-bank-dehint.patch"
  "paygoat|https://github.com/stuxctf/PAYGoat.git|69589b4||paygoat-lab.patch"
  "xben|https://github.com/xbow-engineering/validation-benchmarks.git|a16cb1b|benchmarks/XBEN-090-24|xben-090-base-image.patch"
)

for entry in "${TARGETS[@]}"; do
  IFS='|' read -r name repo commit sparse patch <<< "$entry"
  dir="src/$name"

  if [[ ! -d "$dir/.git" ]]; then
    echo "==> Cloning $name"
    if [[ -n "$sparse" ]]; then
      git clone -q --filter=blob:none --sparse "$repo" "$dir"
      git -C "$dir" sparse-checkout set "$sparse"
    else
      git clone -q "$repo" "$dir"
    fi
  fi

  if [[ "$(git -C "$dir" rev-parse --short=7 HEAD)" != "${commit:0:7}" ]]; then
    echo "==> Checking out $name @ $commit"
    git -C "$dir" checkout -q "$commit"
  fi

  if git -C "$dir" apply --reverse --check "../../patches/$patch" 2>/dev/null; then
    echo "==> $name: $patch already applied"
  else
    echo "==> $name: applying $patch"
    git -C "$dir" apply "../../patches/$patch"
  fi
done

echo "Done. Start the lab with: docker compose -f lab/docker-compose.yml up -d --build"
