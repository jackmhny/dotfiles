#!/bin/bash

# Function to choose a directory using wofi
choose_directory() {
    # Define directories to choose from
    DIRS=("$HOME/Pictures/tiles" "$HOME/Pictures/grayscale-tiles" "$HOME/Pictures/gradient-tiles")
    
    # Use wofi to let user select a directory
    SELECTED_DIR=$(printf '%s\n' "${DIRS[@]}" | wofi --dmenu --prompt="Select tiles directory:")
    
    # Check if user selected a directory
    if [ -z "$SELECTED_DIR" ]; then
        notify-send "Tile Selector" "No directory selected, exiting."
        exit 1
    fi
    
    echo "$SELECTED_DIR"
}

# Function to apply a random tile
apply_random_tile() {
    local tiles_dir="$1"
    
    # Check if directory exists and contains pattern files
    if [ ! -d "$tiles_dir" ] || [ -z "$(ls "$tiles_dir"/pattern_*.gif 2>/dev/null)" ]; then
        notify-send "Tile Selector Error" "No pattern files found in $tiles_dir"
        exit 1
    fi
    
    # Select random tile and store the filename
    CHOSEN_TILE=$(ls "$tiles_dir"/pattern_*.gif | shuf -n 1)
    
    # Apply the tile
    swaymsg output "*" bg "$CHOSEN_TILE" tile
    
    # Notify user
    notify-send "Tile Changed" "$(basename "$CHOSEN_TILE")"
    
    # Log to systemd journal
    logger -t sway-tile "Changed tile to: $(basename "$CHOSEN_TILE")"
    
    echo "$CHOSEN_TILE"
}

# Function to show accept/exit dialog
show_accept_exit() {
    local current_tile="$1"
    # ACTION=$(echo -e "Try Another\nAccept\nExit" | wofi --dmenu --prompt="Current tile: $(basename "$current_tile")")
    ACTION=$(echo -e "1. Try Another\n2. Accept\n3. Exit" | wofi --dmenu --prompt="Current tile: $(basename "$current_tile")" --no-sort | cut -d' ' -f2-)
    
    echo "$ACTION"
}

# Main script
main() {
    # Choose directory
    TILES_DIR=$(choose_directory)
    
    # Loop until user accepts or exits
    while true; do
        # Apply random tile
        CURRENT_TILE=$(apply_random_tile "$TILES_DIR")
        
        # Show accept/exit dialog
        ACTION=$(show_accept_exit "$CURRENT_TILE")
        
        case "$ACTION" in
            "Accept")
                notify-send "Tile Selector" "Tile accepted: $(basename "$CURRENT_TILE")"
                break
                ;;
            "Try Another")
                continue
                ;;
            "Exit"|"")
                notify-send "Tile Selector" "Exiting without saving changes"
                exit 0
                ;;
        esac
    done
}

# Run the main function
main
