#!/usr/bin/env bash

rsync -u ./configuration.nix /etc/nixos/configuration.nix
rsync -u ./flake.nix /etc/nixos/flake.nix
rsync -ur --delete ./modules/ /etc/nixos/modules/

rsync -u /etc/nixos/configuration.nix ./configuration.nix
rsync -u /etc/nixos/flake.nix ./flake.nix
rsync -ur --delete /etc/nixos/modules/ ./modules/
