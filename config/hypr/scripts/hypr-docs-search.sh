#!/bin/bash
# Quick search-only version for fast lookups

ARCHIVE_DIR="/home/zack/dev/lib/hyprland-archive"

# Close stdin to prevent inheritance from parent process
exec 0</dev/null

# Get search query
query=$(walker --dmenu -p "🔍 Search Hyprland Docs")

if [[ -z "$query" ]]; then
    exit 0
fi

# Search and format results
results=$(grep -rn --include="*.md" -i "$query" "$ARCHIVE_DIR" | \
    sed 's|'"$ARCHIVE_DIR"'/||' | \
    awk -F: '{
        file=$1
        line=$2
        gsub(/\.md$/, "", file)
        content=substr($0, index($0,$3))
        if (length(content) > 80) content=substr(content, 1, 77)"..."
        printf "%-35s  Line %-4s  %s\n", file, line, content
    }' | \
    head -30)

if [[ -z "$results" ]]; then
    notify-send "📚 Hyprland Docs" "No results found for: $query" -u normal
    exit 0
fi

# Show results and select
selected=$(echo "$results" | walker --dmenu -p "Results for '$query'")

if [[ -n "$selected" ]]; then
    # Extract filename and line number
    file=$(echo "$selected" | awk '{print $1}')
    line=$(echo "$selected" | awk '{print $3}')

    full_path="$ARCHIVE_DIR/${file}.md"

    # Open in terminal with bat or less
    if command -v bat &> /dev/null; then
        ghostty --class=floating-docs --title="📚 $file" \
            bash -c "bat --paging=always --style=numbers,header --line-range $line: --theme=Catppuccin-mocha '$full_path'"
    else
        ghostty --class=floating-docs --title="📚 $file" \
            bash -c "less +$line '$full_path'"
    fi
fi
