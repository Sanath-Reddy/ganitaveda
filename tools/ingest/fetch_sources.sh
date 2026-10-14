#!/usr/bin/env bash
# Fetch the raw source texts used by tools/ingest and check them against SHA256SUMS.
set -euo pipefail
cd "$(dirname "$0")/raw"
G=https://gretil.sub.uni-goettingen.de/gretil/corpustei
curl -fsSL -o sa_bhAskara-lIlAvatI.txt "$G/transformations/plaintext/sa_bhAskara-lIlAvatI.txt"
curl -fsSL -o sa_brahmagupta-brAhmasphuTasiddhAnta.txt "$G/transformations/plaintext/sa_brahmagupta-brAhmasphuTasiddhAnta.txt"
curl -fsSL -o arya.xml "$G/sa_AryabhaTa-AryabhaTIya-comm.xml"
curl -fsSL -o colebrooke_djvu.txt https://archive.org/download/algebrawitharith00brahuoft/algebrawitharith00brahuoft_djvu.txt
curl -fsSL -o clark_djvu.txt https://archive.org/download/TheAryabhatiyaOfAryabhata/TheAryabhatiyaOfAryabhata_djvu.txt
sha256sum -c SHA256SUMS
