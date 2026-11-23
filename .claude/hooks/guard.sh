#!/bin/bash
# Blocks deploys and secret reads, whichever tool Claude uses
input=$(cat)
if echo "$input" | grep -qE 'firebase +deploy|secrets\.properties'; then
  echo "Blocked by project rule. Ask the user to do this themselves." >&2
  exit 2
fi
exit 0
