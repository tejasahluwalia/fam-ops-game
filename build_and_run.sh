#!/usr/bin/env bash

godot --headless --export-debug LinuxServer dist/server && ./dist/server.sh
