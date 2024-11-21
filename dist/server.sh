#!/bin/sh
echo -ne '\033c\033]0;Twin Shooter Starting Kit\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/server.x86_64" "$@"
