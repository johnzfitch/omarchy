#!/bin/bash
# Omarchy Documentation Browser - Redesigned
# Based on hyprland docs browser architecture for better UX

ARCHIVE_PATH="/home/zack/dev/lib/omarchy-archive"
EDITOR="${EDITOR:-nvim}"
TERMINAL="${TERMINAL:-ghostty}"

# Function: Search and display results with line numbers
search_docs() {
    local query="$1"

    if [[ -z "$query" ]]; then
        return 1
    fi

    # Search with line numbers and nice formatting
    grep -rn --include="*.md" -i "$query" "$ARCHIVE_PATH" | \
        sed 's|'"$ARCHIVE_PATH"'/||' | \
        awk -F: '{
            file=$1
            line=$2
            gsub(/\.md$/, "", file)
            content=substr($0, index($0,$3))
            # Truncate and clean content preview
            gsub(/^[[:space:]]+/, "", content)
            if (length(content) > 85) content=substr(content, 1, 82)"..."
            printf "%-40s │ L%-5s │ %s\n", file, line, content
        }' | head -50
}

# Function: Handle selection with action menu
handle_selection() {
    local selected="$1"
    local file line full_path dir

    # Parse selection (use sed instead of cut for Unicode)
    file=$(echo "$selected" | sed 's/ │.*//' | sed 's/[[:space:]]*$//')
    line=$(echo "$selected" | awk -F'│' '{print $2}' | grep -oP '\d+')
    full_path="$ARCHIVE_PATH/${file}.md"
    dir=$(dirname "$full_path")

    # Action menu
    local action=$(cat <<EOF | omarchy-launch-walker --dmenu -p "📋 Select Action" --width 600 --maxheight 250
📖 Open in Editor (line $line)
👁️  Preview with bat
📋 Copy path to clipboard
📁 Open directory in file manager
🔗 Copy line reference
EOF
)

    case "$action" in
        *"Editor"*)
            # Open in editor at specific line - simple spawn + tag (no race condition)
            # Pass as single command with explicit nvim path to ensure proper line navigation
            $TERMINAL --class=omarchy-docs-editor --title="📚 Omarchy Docs" \
                -e bash -c "${EDITOR:-nvim} +${line:-1} \"$full_path\"" &

            # Tag after spawn (prevents race condition)
            sleep 0.15
            hyprctl dispatch tagwindow +omarchy-editor class:^omarchy-docs-editor$ >/dev/null 2>&1
            ;;

        *"Preview"*)
            # Preview with bat - simple spawn + tag (no race condition)
            if command -v bat &> /dev/null; then
                $TERMINAL --class=omarchy-docs-preview --title="📚 ${file##*/}" \
                    -e bat --paging=always --style=numbers,header,grid \
                         --line-range "$line": "$full_path" &
            else
                $TERMINAL --class=omarchy-docs-preview --title="📚 ${file##*/}" \
                    -e less +"$line" "$full_path" &
            fi

            # Tag after spawn
            sleep 0.15
            hyprctl dispatch tagwindow +omarchy-docs class:^omarchy-docs-preview$ >/dev/null 2>&1
            ;;

        *"Copy path"*)
            # Copy full path
            echo -n "$full_path" | wl-copy
            notify-send "📋 Copied" "$full_path" -u low -t 2500
            ;;

        *"directory"*)
            # Open directory
            nautilus "$dir" &
            notify-send "📁 Directory Opened" "$dir" -u low -t 2000
            ;;

        *"line reference"*)
            # Copy markdown-style reference
            reference="${file}.md:${line}"
            echo -n "$reference" | wl-copy
            notify-send "🔗 Reference Copied" "$reference" -u low -t 2500
            ;;
    esac
}

# Main menu options
show_main_menu() {
    local choice=$(cat <<EOF | omarchy-launch-walker --dmenu -p " Omarchy Docs" --width 400 --maxheight 480
 Search All Docs
 Browse by Category
 Quick Reference
 Troubleshooting
 FAQ
 Script Index
 Popular Topics
 Remount Network Drives
🔓 Start SSH Server
🔒 Stop SSH Server
🔐 Start DNS Tunnel
🔓 Stop DNS Tunnel
📊 DNS Tunnel Status
EOF
)

    case "$choice" in
        *"Search All"*)
            search_all_docs
            ;;
        *"Browse by Category"*)
            browse_categories
            ;;
        *"Quick Reference"*)
            quick_open "$ARCHIVE_PATH/10-reference/quick-reference.md"
            ;;
        *"Troubleshooting"*)
            quick_open "$ARCHIVE_PATH/10-reference/troubleshooting.md"
            ;;
        *"FAQ"*)
            quick_open "$ARCHIVE_PATH/10-reference/faq.md"
            ;;
        *"Script Index"*)
            quick_open "$ARCHIVE_PATH/SCRIPT-MAP.md"
            ;;
        *"Popular Topics"*)
            popular_topics
            ;;
        *"Remount Network"*)
            "$HOME/.local/bin/remount-network-drives"
            notify-send "🔌 Network Drives" "Remounting all network drives..." -u low -t 2000
            ;;
        *"Start SSH"*)
            "$HOME/.local/bin/ssh-on"
            ;;
        *"Stop SSH"*)
            "$HOME/.local/bin/ssh-off"
            ;;
        *"Start DNS Tunnel"*)
            $TERMINAL --class=omarchy-dns-tunnel --title="DNS Privacy Tunnel" \
                -e "$HOME/.local/bin/dns-tunnel-on" &
            ;;
        *"Stop DNS Tunnel"*)
            "$HOME/.local/bin/dns-tunnel-off"
            notify-send "🔓 DNS Tunnel" "Stopping DNS privacy tunnel..." -u low -t 2000
            ;;
        *"DNS Tunnel Status"*)
            $TERMINAL --class=omarchy-dns-status --title="DNS Tunnel Status" \
                -e "$HOME/.local/bin/dns-tunnel-status" &
            ;;
        *)
            exit 0
            ;;
    esac
}

# Search all docs - streamlined flow
search_all_docs() {
    # Step 1: Get search query
    local query=$(echo "" | omarchy-launch-walker --dmenu -p "🔍 Search omarchy docs" --width 500)

    if [[ -z "$query" ]]; then
        show_main_menu
        return
    fi

    # Step 2: Search and get results
    local results=$(search_docs "$query")

    if [[ -z "$results" ]]; then
        notify-send "📚 Omarchy Docs" "No results found for: $query" -u normal -t 3000
        show_main_menu
        return
    fi

    # Count results
    local result_count=$(echo "$results" | wc -l)

    # Step 3: Show results directly
    local selected=$(echo "$results" | omarchy-launch-walker --dmenu \
        -p "📄 $result_count results for '$query'" \
        --width 1100 --maxheight 600)

    if [[ -z "$selected" ]]; then
        show_main_menu
        return
    fi

    # Step 4: Handle the selection with action menu
    handle_selection "$selected"
}

# Browse by category
browse_categories() {
    local category=$(cat <<EOF | omarchy-launch-walker --dmenu -p "📂 Select Category" --width 400
01-getting-started
02-core-commands
03-theming
04-desktop-environment
05-applications
06-development
07-system-setup
08-utilities
09-customization
10-reference
EOF
)

    if [[ -z "$category" ]]; then
        show_main_menu
        return
    fi

    # List files in category
    local files=$(find "$ARCHIVE_PATH/$category" -name "*.md" -type f -exec basename {} \; | sed 's|\.md$||' | sort)

    local selected_file=$(echo "$files" | omarchy-launch-walker --dmenu -p "Select File" --width 400)

    if [[ -n "$selected_file" ]]; then
        quick_open "$ARCHIVE_PATH/$category/$selected_file.md"
    else
        show_main_menu
    fi
}

# Popular topics - quick jump menu
popular_topics() {
    local topic=$(cat <<EOF | omarchy-launch-walker --dmenu -p "🎯 Jump to Topic" --width 450
Theme System
Package Management
Hyprland Configuration
Walker & Elephant
Window Management
Keybindings
Screenshot & Recording
Development Setup
Creating Custom Themes
Audio & Bluetooth Setup
Monitor Configuration
Power Management
Config Management
First Run Guide
Installation
Architecture Overview
EOF
)

    case "$topic" in
        "Theme System") quick_open "$ARCHIVE_PATH/03-theming/theme-system.md" ;;
        "Package Management") quick_open "$ARCHIVE_PATH/02-core-commands/package-management.md" ;;
        "Hyprland Configuration") quick_open "$ARCHIVE_PATH/04-desktop-environment/hyprland-integration.md" ;;
        "Walker & Elephant") quick_open "$ARCHIVE_PATH/04-desktop-environment/walker-elephant.md" ;;
        "Window Management") quick_open "$ARCHIVE_PATH/04-desktop-environment/window-management.md" ;;
        "Keybindings") quick_open "$ARCHIVE_PATH/09-customization/keybindings.md" ;;
        "Screenshot & Recording") quick_open "$ARCHIVE_PATH/08-utilities/screenshot-screenrecord.md" ;;
        "Development Setup") quick_open "$ARCHIVE_PATH/06-development/editor-setup.md" ;;
        "Creating Custom Themes") quick_open "$ARCHIVE_PATH/03-theming/creating-themes.md" ;;
        "Audio & Bluetooth Setup") quick_open "$ARCHIVE_PATH/07-system-setup/audio-bluetooth-wifi.md" ;;
        "Monitor Configuration") quick_open "$ARCHIVE_PATH/07-system-setup/monitors-input.md" ;;
        "Power Management") quick_open "$ARCHIVE_PATH/07-system-setup/power-management.md" ;;
        "Config Management") quick_open "$ARCHIVE_PATH/09-customization/config-management.md" ;;
        "First Run Guide") quick_open "$ARCHIVE_PATH/01-getting-started/first-run-guide.md" ;;
        "Installation") quick_open "$ARCHIVE_PATH/01-getting-started/installation.md" ;;
        "Architecture Overview") quick_open "$ARCHIVE_PATH/01-getting-started/architecture.md" ;;
        *)
            show_main_menu
            ;;
    esac
}

# Quick open a file with action menu
quick_open() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        notify-send "Omarchy Docs" "File not found: $file" -u critical
        show_main_menu
        return
    fi

    local basename=$(basename "$file" .md)

    # Action menu
    local action=$(cat <<EOF | omarchy-launch-walker --dmenu -p "📋 Open: $basename" --width 500 --maxheight 250
📖 Open in Editor
👁️  Preview with bat
📋 Copy path to clipboard
📁 Open directory in file manager
EOF
)

    case "$action" in
        *"Editor"*)
            $TERMINAL --class=omarchy-docs-editor --title="📚 Omarchy Docs" \
                -e bash -c "${EDITOR:-nvim} \"$file\"" &

            sleep 0.15
            hyprctl dispatch tagwindow +omarchy-editor class:^omarchy-docs-editor$ >/dev/null 2>&1
            ;;

        *"Preview"*)
            if command -v bat &> /dev/null; then
                $TERMINAL --class=omarchy-docs-preview --title="📚 $basename" \
                    -e bat --paging=always --style=numbers,header,grid "$file" &
            else
                $TERMINAL --class=omarchy-docs-preview --title="📚 $basename" \
                    -e less "$file" &
            fi

            sleep 0.15
            hyprctl dispatch tagwindow +omarchy-docs class:^omarchy-docs-preview$ >/dev/null 2>&1
            ;;

        *"Copy path"*)
            echo -n "$file" | wl-copy
            notify-send "📋 Copied" "$file" -u low -t 2500
            ;;

        *"directory"*)
            nautilus "$(dirname "$file")" &
            notify-send "📁 Directory Opened" "$(dirname "$file")" -u low -t 2000
            ;;
    esac
}

# Check if archive exists
if [[ ! -d "$ARCHIVE_PATH" ]]; then
    notify-send "Omarchy Docs" "Archive not found at $ARCHIVE_PATH" -u critical
    exit 1
fi

# Start main menu (redirect stdin to prevent inheritance from parent process)
show_main_menu </dev/null
