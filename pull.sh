#!/bin/bash
set -x

CR_PAT=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

if [ -z "$CR_PAT" ]; then
  echo "CR_PAT environment variable is not set"
  exit 1;
fi
echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin

docker-compose pull
