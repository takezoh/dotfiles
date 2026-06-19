# Claude Code aliases
alias claude='claude --enable-auto-mode'

# OPUS_MODEL="opus[1m]"
OPUS_MODEL="claude-opus-4-7[1m]"
SONNET_MODEL="sonnet"
OPUSPLAN_MODEL="opusplan"

# Model + effort combinations
alias sonnet-medium='claude --model '$SONNET_MODEL' --effort medium'
alias sonnet-high='claude --model '$SONNET_MODEL' --effort high'
alias opus-xhigh='claude --model "'$OPUS_MODEL'" --effort xhigh'
alias opus-max='claude --model "'$OPUS_MODEL'" --effort max'
alias opusplan-high='claude --model '$OPUSPLAN_MODEL' --effort high'
