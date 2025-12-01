#!/bin/bash

# Build metadata cache for omarchy documentation
# This creates a fast-lookup cache of semantic summaries

ARCHIVE_PATH="/home/zack/dev/lib/omarchy-archive"
CACHE_FILE="$ARCHIVE_PATH/.metadata-cache"

echo "Building omarchy docs metadata cache..."

# Clear existing cache
> "$CACHE_FILE"

# Process all markdown files
find "$ARCHIVE_PATH" -name "*.md" -type f | while IFS= read -r file; do
    # Skip cache file itself
    [[ "$file" == "$CACHE_FILE" ]] && continue

    # Get relative path
    rel_path="${file#$ARCHIVE_PATH/}"

    # Extract semantic summary
    summary=""

    # Try Purpose line
    summary=$(grep -i "^\*\*Purpose\*\*:" "$file" 2>/dev/null | head -1 | sed 's/^\*\*Purpose\*\*:[[:space:]]*//' | sed 's/[*`]//g')

    # Try Use Case line
    if [[ -z "$summary" ]]; then
        summary=$(grep -i "^\*\*Use Case\*\*:" "$file" 2>/dev/null | head -1 | sed 's/^\*\*Use Case\*\*:[[:space:]]*//' | sed 's/[*`]//g')
    fi

    # Try Overview section
    if [[ -z "$summary" ]]; then
        summary=$(sed -n '/^## Overview/,/^##/p' "$file" 2>/dev/null | \
            grep -v "^##" | \
            grep -v "^$" | \
            head -1 | \
            sed 's/^[[:space:]]*//' | \
            sed 's/[#*`-]//g')
    fi

    # Use first paragraph as fallback
    if [[ -z "$summary" ]]; then
        summary=$(grep -v "^#" "$file" 2>/dev/null | \
            grep -v "^$" | \
            grep -v "^---" | \
            grep -v "^\*Last Updated" | \
            head -1 | \
            sed 's/^[[:space:]]*//' | \
            sed 's/[*`]//g')
    fi

    # Truncate to 12 words
    short_summary=$(echo "$summary" | awk '{for(i=1;i<=12;i++) printf "%s ", $i}' | sed 's/[[:space:]]*$//')

    # Fallback
    if [[ -z "$short_summary" ]]; then
        short_summary="Documentation file"
    fi

    # Write to cache: filepath|summary
    echo "${rel_path}|${short_summary}" >> "$CACHE_FILE"
done

# Count entries
entry_count=$(wc -l < "$CACHE_FILE")

echo "✓ Cache built: $entry_count files indexed"
echo "✓ Cache location: $CACHE_FILE"
