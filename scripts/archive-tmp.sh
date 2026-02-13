#!/bin/bash

# archive-tmp.sh - Archive ~/dev/tmp to a named folder using AI-generated names
# Usage: ./archive-tmp.sh [--nuke]

TMP_DIR="$HOME/dev/tmp"
DEST_BASE="$HOME/dev"
OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-}"

# Parse arguments
NUKE_MODE=false
if [[ "$1" == "--nuke" ]]; then
    NUKE_MODE=true
fi

if [[ "$NUKE_MODE" == true ]]; then
    echo "Nuke mode: Clearing $TMP_DIR without archiving..."
    find "$TMP_DIR" -mindepth 1 -delete
    echo "Done. tmp is now empty."
    exit 0
fi

# Check if tmp is empty
if [[ -z "$(ls -A "$TMP_DIR" 2>/dev/null)" ]]; then
    echo "tmp is already empty. Nothing to archive."
    exit 0
fi

# Get a summary of what's in tmp for the AI
TMP_SUMMARY=$(ls -la "$TMP_DIR" | head -20)
FILE_LIST=$(find "$TMP_DIR" -type f -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.json" -o -name "*.md" -o -name "*.txt" | head -10)

# Build prompt for AI
PROMPT="Looking at this directory listing:

$TMP_SUMMARY

And these key files: $FILE_LIST

Generate a short, descriptive, kebab-case folder name (2-4 words) that describes what this project appears to be. Use only lowercase letters, numbers, and hyphens. No spaces. Examples: 'world-map-generator', 'data-processor', 'api-client-tool', 'image-converter'. Return ONLY the folder name, nothing else."

echo "Generating folder name via AI..."

# Call OpenRouter API
if [[ -n "$OPENROUTER_API_KEY" ]]; then
    AI_RESPONSE=$(curl -s -X POST "https://openrouter.ai/api/v1/chat/completions" \
        -H "Authorization: Bearer $OPENROUTER_API_KEY" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"openai/gpt-oss-120b\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}],
            \"max_tokens\": 150
        }" 2>/dev/null)
    
    # Extract folder name from response - try content first, then reasoning
    if command -v jq &> /dev/null; then
        FOLDER_NAME=$(echo "$AI_RESPONSE" | jq -r '.choices[0].message.content' 2>/dev/null | head -1)
        # If content is empty, try reasoning
        if [[ -z "$FOLDER_NAME" ]]; then
            FOLDER_NAME=$(echo "$AI_RESPONSE" | jq -r '.choices[0].message.reasoning' 2>/dev/null | head -1)
        fi
    else
        FOLDER_NAME=$(echo "$AI_RESPONSE" | sed -n 's/.*"content":"\([^"]*\)".*/\1/p' | head -1)
    fi
    FOLDER_NAME=$(echo "$FOLDER_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
    
    # Clean up the name
    FOLDER_NAME=$(echo "$FOLDER_NAME" | sed 's/^-*//;s/-*$//;s/-\+/-/g')
    
    if [[ -z "$FOLDER_NAME" ]] || [[ ${#FOLDER_NAME} -lt 2 ]]; then
        # Fallback: use timestamp
        FOLDER_NAME="archive-$(date +%Y%m%d-%H%M%S)"
        echo "AI failed to generate name, using timestamp: $FOLDER_NAME"
    else
        echo "AI suggested: $FOLDER_NAME"
    fi
else
    # No API key, use timestamp
    FOLDER_NAME="archive-$(date +%Y%m%d-%H%M%S)"
    echo "No OPENROUTER_API_KEY set, using timestamp: $FOLDER_NAME"
fi

# Create destination folder
DEST_DIR="$DEST_BASE/$FOLDER_NAME"

# Handle duplicates
COUNTER=1
ORIGINAL_NAME="$FOLDER_NAME"
while [[ -d "$DEST_DIR" ]]; do
    FOLDER_NAME="${ORIGINAL_NAME}-${COUNTER}"
    DEST_DIR="$DEST_BASE/$FOLDER_NAME"
    ((COUNTER++))
done

# Copy and clear
mkdir -p "$DEST_DIR"
cp -r "$TMP_DIR"/. "$DEST_DIR/"
find "$TMP_DIR" -mindepth 1 -delete

echo ""
echo "✓ Archived to: $DEST_DIR"
echo "✓ tmp is now empty"
