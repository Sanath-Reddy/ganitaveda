#!/usr/bin/env bash
# Checks that every native library in an AAB or APK has 16 KB-aligned LOAD
# segments (plan §6.12). Needs llvm-objdump or objdump on PATH.
set -euo pipefail
archive="$1"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
unzip -q "$archive" '*.so' -d "$tmp" || { echo "no native libraries"; exit 0; }
fail=0
while IFS= read -r so; do
  dump=$(command -v llvm-objdump || command -v objdump)
  aligns=$("$dump" -p "$so" | awk '/LOAD/ {print $NF}')
  for a in $aligns; do
    # align is printed as 2**N; 16 KB is 2**14
    n=${a##*\*}
    if [ "$n" -lt 14 ]; then echo "NOT 16KB aligned: ${so#$tmp/} ($a)"; fail=1; fi
  done
done < <(find "$tmp" -name '*.so')
[ $fail -eq 0 ] && echo "all native libraries are 16 KB aligned"
exit $fail
