# Run this on scout (100.64.0.1) to set up opencode

# 1. Install opencode if not already installed
curl -L https://opencode.ai/install.sh | bash

# 2. Add to ~/.bashrc or ~/.zshrc:
# export OPENROUTER_API_KEY="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"

# 3. Create ~/bin/oc (ensure ~/bin is in PATH)
mkdir -p ~/bin
cat > ~/bin/oc << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

MODEL="openrouter/minimax/minimax-m2.7"

if [[ "${1:-}" == "-t" ]]; then
    session="oc-$(date +%H%M%S)"
    tmux new-session -d -s "$session" "opencode -m $MODEL"
    exec tmux attach-session -t "$session"
else
    exec opencode -m "$MODEL" "$@"
fi
EOF
chmod +x ~/bin/oc

# 4. Add to shell rc for oc alias + PATH:
# export PATH="$HOME/bin:$PATH"
# alias oc='oc'

# 5. Verify
# oc --version
