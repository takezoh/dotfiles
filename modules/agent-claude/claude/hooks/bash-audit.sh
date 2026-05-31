#!/usr/bin/env bash
jq -r '[(now|todate), .tool_input.command] | @tsv' >> ~/.claude/command-log.txt
