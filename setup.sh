#!/bin/bash

git config --local filter.sops.required true
git config --local filter.sops.clean './.sops-filter.pl clean %f'
git config --local filter.sops.smudge './.sops-filter.pl smudge %f'
git config --local diff.sops.textconv 'cat'

rm .git/index
git checkout HEAD -- .
