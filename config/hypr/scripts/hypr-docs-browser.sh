#!/bin/bash
# Hyprland Documentation Browser
# Interactive archive search and browse with rofi/wofi

ARCHIVE_DIR="/home/zack/dev/lib/hyprland-archive"
LAUNCHER="${HYPR_LAUNCHER:-walker}" # walker, rofi, or wofi

# Colors (Catppuccin Mocha inspired)
ROFI_THEME="
* {
    bg: #1e1e2e;
    bg-alt: #313244;
    fg: #cdd6f4;
    fg-alt: #bac2de;
    accent: #89b4fa;
    urgent: #f38ba8;

    background-color: @bg;
    text-color: @fg;
}

window {
    width: 50%;
    height: 60%;
    border: 2px;
    border-color: @accent;
    border-radius: 10px;
}

mainbox {
    padding: 10px;
}

inputbar {
    background-color: @bg-alt;
    text-color: @fg;
    border-radius: 5px;
    padding: 8px 12px;
    margin: 0px 0px 10px 0px;
    children: [prompt, entry];
}

prompt {
    text-color: @accent;
    padding: 0px 10px 0px 0px;
}

entry {
    text-color: @fg;
}

listview {
    lines: 12;
    scrollbar: true;
}

scrollbar {
    handle-color: @accent;
    handle-width: 4px;
}

element {
    padding: 8px;
    border-radius: 5px;
}

element selected {
    background-color: @accent;
    text-color: @bg;
}

element-text {
    text-color: inherit;
}
"

# Function to show menu with rofi
show_rofi_menu() {
    local prompt="$1"
    shift
    echo "$ROFI_THEME" | rofi -dmenu -i -p "$prompt" -theme-str "$ROFI_THEME" "$@"
}

# Function to show menu with wofi
show_wofi_menu() {
    local prompt="$1"
    shift
    wofi --dmenu --prompt "$prompt" --insensitive "$@"
}

# Function to show menu with walker
show_walker_menu() {
    local prompt="$1"
    shift
    walker --dmenu -p "$prompt" "$@"
}

# Choose launcher
show_menu() {
    if [[ "$LAUNCHER" == "wofi" ]]; then
        show_wofi_menu "$@"
    elif [[ "$LAUNCHER" == "walker" ]]; then
        show_walker_menu "$@"
    else
        show_rofi_menu "$@"
    fi
}

# Main menu options
show_main_menu() {
    local choice=$(cat <<EOF | show_menu "📚 Hyprland Docs"
🔍 Search Archive
📖 Browse by Category
⚡ Quick Reference
🛠️ Troubleshooting
❓ FAQ
📝 View Recent Files
🎯 Go to Topic
EOF
)

    case "$choice" in
        "🔍 Search Archive")
            search_archive
            ;;
        "📖 Browse by Category")
            browse_categories
            ;;
        "⚡ Quick Reference")
            open_file "$ARCHIVE_DIR/09-reference/quick-reference.md"
            ;;
        "🛠️ Troubleshooting")
            open_file "$ARCHIVE_DIR/09-reference/troubleshooting.md"
            ;;
        "❓ FAQ")
            open_file "$ARCHIVE_DIR/09-reference/faq.md"
            ;;
        "📝 View Recent Files")
            view_recent_files
            ;;
        "🎯 Go to Topic")
            goto_topic
            ;;
    esac
}

# Search the archive
search_archive() {
    local query=$(echo "" | show_menu "🔍 Search for:")

    if [[ -z "$query" ]]; then
        return
    fi

    # Search and format results
    local results=$(grep -rn --include="*.md" "$query" "$ARCHIVE_DIR" | \
        sed 's|'"$ARCHIVE_DIR"'/||' | \
        awk -F: '{printf "%-40s Line %-5s %s\n", $1, $2, substr($0, index($0,$3))}' | \
        head -50)

    if [[ -z "$results" ]]; then
        notify-send "📚 Hyprland Docs" "No results found for: $query"
        return
    fi

    # Select result
    local selected=$(echo "$results" | show_menu "Results for '$query'")

    if [[ -n "$selected" ]]; then
        local file=$(echo "$selected" | awk '{print $1}')
        local line=$(echo "$selected" | awk '{print $3}')
        open_file "$ARCHIVE_DIR/$file" "$line"
    fi
}

# Browse by category
browse_categories() {
    local category=$(cat <<EOF | show_menu "📂 Select Category"
01 Core Configuration
02 Visual Effects
03 Performance & Hardware
04 System Integration
05 Hypr Ecosystem
06 Utilities & Apps
07 Advanced Topics
08 Getting Started
09 Quick Reference
EOF
)

    case "$category" in
        "01 Core Configuration")
            browse_files "$ARCHIVE_DIR/01-core-config" "⚙️ Core Config"
            ;;
        "02 Visual Effects")
            browse_files "$ARCHIVE_DIR/02-visual-effects" "✨ Visual"
            ;;
        "03 Performance & Hardware")
            browse_files "$ARCHIVE_DIR/03-performance" "⚡ Performance"
            ;;
        "04 System Integration")
            browse_files "$ARCHIVE_DIR/04-system-integration" "🔧 System"
            ;;
        "05 Hypr Ecosystem")
            browse_files "$ARCHIVE_DIR/05-ecosystem" "🛠️ Ecosystem"
            ;;
        "06 Utilities & Apps")
            browse_files "$ARCHIVE_DIR/06-utilities" "📦 Utilities"
            ;;
        "07 Advanced Topics")
            browse_files "$ARCHIVE_DIR/07-advanced" "🎓 Advanced"
            ;;
        "08 Getting Started")
            browse_files "$ARCHIVE_DIR/08-getting-started" "🚀 Getting Started"
            ;;
        "09 Quick Reference")
            browse_files "$ARCHIVE_DIR/09-reference" "📖 Reference"
            ;;
    esac
}

# Browse files in directory
browse_files() {
    local dir="$1"
    local prompt="$2"

    local file=$(find "$dir" -name "*.md" -type f | \
        sed 's|.*/||' | \
        sed 's|\.md$||' | \
        sort | \
        show_menu "$prompt")

    if [[ -n "$file" ]]; then
        local full_path=$(find "$dir" -name "${file}.md" -type f)
        open_file "$full_path"
    fi
}

# Quick topic jump
goto_topic() {
    local topic=$(cat <<EOF | show_menu "🎯 Jump to Topic"
Monitor Configuration
Window Rules
Workspace Rules
Keybindings
Dispatchers
Variables Reference
hyprctl Reference
Animations
Layouts
Performance Optimization
NVIDIA Setup
Multi-GPU
Screen Tearing & VRR
Environment Variables
XWayland
Systemd Integration
IPC & Events
Plugin Development
NixOS Integration
Installation Guide
Tutorial
Quick Reference
Troubleshooting
FAQ
Common Patterns
EOF
)

    case "$topic" in
        "Monitor Configuration") open_file "$ARCHIVE_DIR/01-core-config/monitors.md" ;;
        "Window Rules") open_file "$ARCHIVE_DIR/01-core-config/window-rules.md" ;;
        "Workspace Rules") open_file "$ARCHIVE_DIR/01-core-config/workspace-rules.md" ;;
        "Keybindings") open_file "$ARCHIVE_DIR/01-core-config/bindings.md" ;;
        "Dispatchers") open_file "$ARCHIVE_DIR/01-core-config/dispatchers.md" ;;
        "Variables Reference") open_file "$ARCHIVE_DIR/01-core-config/variables.md" ;;
        "hyprctl Reference") open_file "$ARCHIVE_DIR/01-core-config/hyprctl.md" ;;
        "Animations") open_file "$ARCHIVE_DIR/02-visual-effects/animations.md" ;;
        "Layouts") open_file "$ARCHIVE_DIR/02-visual-effects/layouts.md" ;;
        "Performance Optimization") open_file "$ARCHIVE_DIR/03-performance/optimization.md" ;;
        "NVIDIA Setup") open_file "$ARCHIVE_DIR/03-performance/nvidia.md" ;;
        "Multi-GPU") open_file "$ARCHIVE_DIR/03-performance/multi-gpu.md" ;;
        "Screen Tearing & VRR") open_file "$ARCHIVE_DIR/03-performance/tearing.md" ;;
        "Environment Variables") open_file "$ARCHIVE_DIR/04-system-integration/environment.md" ;;
        "XWayland") open_file "$ARCHIVE_DIR/04-system-integration/xwayland.md" ;;
        "Systemd Integration") open_file "$ARCHIVE_DIR/04-system-integration/systemd.md" ;;
        "IPC & Events") open_file "$ARCHIVE_DIR/07-advanced/ipc.md" ;;
        "Plugin Development") open_file "$ARCHIVE_DIR/07-advanced/plugins.md" ;;
        "NixOS Integration") open_file "$ARCHIVE_DIR/07-advanced/nix.md" ;;
        "Installation Guide") open_file "$ARCHIVE_DIR/08-getting-started/installation.md" ;;
        "Tutorial") open_file "$ARCHIVE_DIR/08-getting-started/tutorial.md" ;;
        "Quick Reference") open_file "$ARCHIVE_DIR/09-reference/quick-reference.md" ;;
        "Troubleshooting") open_file "$ARCHIVE_DIR/09-reference/troubleshooting.md" ;;
        "FAQ") open_file "$ARCHIVE_DIR/09-reference/faq.md" ;;
        "Common Patterns") open_file "$ARCHIVE_DIR/09-reference/common-patterns.md" ;;
    esac
}

# View recently modified files
view_recent_files() {
    local file=$(find "$ARCHIVE_DIR" -name "*.md" -type f -printf '%T@ %p\n' | \
        sort -rn | \
        head -10 | \
        cut -d' ' -f2- | \
        sed 's|'"$ARCHIVE_DIR"'/||' | \
        sed 's|\.md$||' | \
        show_menu "📝 Recent Files")

    if [[ -n "$file" ]]; then
        open_file "$ARCHIVE_DIR/${file}.md"
    fi
}

# Open file in terminal or editor
open_file() {
    local file="$1"
    local line="${2:-1}"

    # Choose how to open based on preference
    if command -v bat &> /dev/null; then
        # Use bat with pager in floating terminal
        ghostty --class=floating-docs --title="📚 Hyprland Docs" \
            bash -c "bat --paging=always --style=numbers,header --theme=Catppuccin-mocha '$file'"
    elif command -v less &> /dev/null; then
        # Use less in floating terminal
        ghostty --class=floating-docs --title="📚 Hyprland Docs" \
            bash -c "less +${line} '$file'"
    else
        # Fallback to cat
        ghostty --class=floating-docs --title="📚 Hyprland Docs" \
            bash -c "cat '$file' | less"
    fi
}

# Run main menu (redirect stdin to prevent inheritance from parent process)
show_main_menu </dev/null
