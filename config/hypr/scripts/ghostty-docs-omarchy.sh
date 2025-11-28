#!/bin/bash
# Omarchy-native Ghostty Documentation Browser
# Integrates with walker's theming and action system

ARCHIVE_DIR="/home/zack/dev/lib/ghostty-wiki"
EDITOR="${EDITOR:-nvim}"
TERMINAL="${TERMINAL:-ghostty}"

# Function: Search and display results
search_docs() {
    local query="$1"

    if [[ -z "$query" ]]; then
        return 1
    fi

    # Search with nice formatting
    grep -rn --include="*.md" -i "$query" "$ARCHIVE_DIR" | \
        sed 's|'"$ARCHIVE_DIR"'/||' | \
        awk -F: '{
            file=$1
            line=$2
            gsub(/\.md$/, "", file)
            content=substr($0, index($0,$3))
            # Truncate and clean
            gsub(/^[[:space:]]+/, "", content)
            if (length(content) > 90) content=substr(content, 1, 87)"..."
            printf "%-42s │ L%-5s │ %s\n", file, line, content
        }' | head -50
}

# Function: Handle selection with actions
handle_selection() {
    local selected="$1"
    local file line full_path dir

    # Parse selection
    file=$(echo "$selected" | awk -F'│' '{print $1}' | sed 's/[[:space:]]*$//')
    line=$(echo "$selected" | awk -F'│' '{print $2}' | grep -oP '\d+')
    full_path="$ARCHIVE_DIR/${file}.md"
    dir=$(dirname "$full_path")

    # Action menu with omarchy-styled walker
    local action=$(cat <<EOF | walker --dmenu -p "📋 Select Action" --width 600 --maxheight 250
📖 Open in Neovim (line $line)
📁 Open directory in Nautilus
📋 Copy path to clipboard
👁️  Preview with bat
🔗 Copy line reference
EOF
)

    case "$action" in
        *"Neovim"*)
            # Open in neovim at specific line - simple spawn + tag (no race condition)
            $TERMINAL --class=ghostty-docs-editor --title="👻 Ghostty Docs" \
                -e bash -c "${EDITOR:-nvim} +${line:-1} \"$full_path\"" &

            # Tag after spawn
            sleep 0.15
            hyprctl dispatch tagwindow +ghostty-editor class:^ghostty-docs-editor$ >/dev/null 2>&1
            ;;

        *"directory"*)
            # Open directory
            nautilus "$dir" &
            notify-send "📁 Directory Opened" "$dir" -u low -t 2000
            ;;

        *"Copy path"*)
            # Copy full path
            echo -n "$full_path" | wl-copy
            notify-send "📋 Copied" "$full_path" -u low -t 2500
            ;;

        *"Preview"*)
            # Preview with bat - simple spawn + tag (no race condition)
            if command -v bat &> /dev/null; then
                $TERMINAL --class=ghostty-docs-preview --title="👻 ${file##*/}" \
                    -e bat --paging=always --style=numbers,header,grid \
                         --line-range "$line": --theme=base16 "$full_path" &
            else
                $TERMINAL --class=ghostty-docs-preview --title="👻 ${file##*/}" \
                    -e less +"$line" "$full_path" &
            fi

            # Tag after spawn
            sleep 0.15
            hyprctl dispatch tagwindow +ghostty-docs class:^ghostty-docs-preview$ >/dev/null 2>&1
            ;;

        *"line reference"*)
            # Copy markdown-style reference
            reference="${file}.md:${line}"
            echo -n "$reference" | wl-copy
            notify-send "🔗 Reference Copied" "$reference" -u low -t 2500
            ;;
    esac
}

# Main execution
main() {
    # Step 1: Get search query
    query=$(omarchy-launch-ghostty-docs)

    if [[ -z "$query" ]]; then
        exit 0
    fi

    # Step 2: Search and get results
    results=$(search_docs "$query")

    if [[ -z "$results" ]]; then
        notify-send "👻 Ghostty Docs" "No results found for: $query" -u normal -t 3000
        exit 0
    fi

    # Count results
    result_count=$(echo "$results" | wc -l)

    # Step 3: Show results with omarchy walker
    selected=$(echo "$results" | walker --dmenu -p "📄 $result_count results for '$query'" \
                                         --width 1000 --maxheight 600)

    if [[ -z "$selected" ]]; then
        exit 0
    fi

    # Step 4: Handle the selection
    handle_selection "$selected"
}

# Redirect stdin to prevent inheritance from parent process
main "$@" </dev/null
