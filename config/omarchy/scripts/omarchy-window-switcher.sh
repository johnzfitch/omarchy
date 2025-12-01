#!/bin/bash
# Hyprland Window Switcher using Walker
# Shows all windows across all workspaces

# Get all windows with their details
windows=$(hyprctl clients -j | jq -r '.[] |
    "\(.address)|\(.workspace.name)|\(.class)|\(.title)"' |
    awk -F'|' '{
        # Truncate title if too long
        title = $4
        if (length(title) > 60) {
            title = substr(title, 1, 57) "..."
        }
        # Format: [WS] Class: Title
        printf "[WS %s] %s: %s|%s\n", $2, $3, title, $1
    }')

if [[ -z "$windows" ]]; then
    notify-send "Window Switcher" "No windows found" -u normal
    exit 0
fi

# Show in Walker and get selected window address
selected=$(echo "$windows" | awk -F'|' '{print $1}' | walker --dmenu --prompt "🪟 Switch to Window")

if [[ -n "$selected" ]]; then
    # Extract address from selection
    address=$(echo "$windows" | grep -F "$selected" | awk -F'|' '{print $2}')

    if [[ -n "$address" ]]; then
        # Focus the selected window
        hyprctl dispatch focuswindow "address:$address"
    fi
fi
