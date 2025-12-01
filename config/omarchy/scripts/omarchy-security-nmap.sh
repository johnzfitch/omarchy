#!/bin/bash
# Interactive Nmap Scanner for Omarchy
# Provides TUI interface for common nmap scans

TERMINAL="${TERMINAL:-ghostty}"

# Helper function to launch terminal on current workspace
launch_tool_terminal() {
    local title="$1"
    local cmd="$2"

    # Get current workspace
    local current_ws=$(hyprctl activeworkspace -j | jq -r '.id')

    # Launch terminal
    $TERMINAL --class=omarchy-security --title="$title" -e bash -c "$cmd" &
    sleep 0.15

    # Tag and move to current workspace
    hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security$ >/dev/null 2>&1
    hyprctl dispatch movetoworkspacesilent $current_ws,class:^omarchy-security$ >/dev/null 2>&1
}

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Scan profiles
declare -A SCAN_PROFILES=(
    ["Quick Scan|Fast scan of top 1000 ports"]="nmap -T4 -F"
    ["Full Port Scan|Scan all 65535 ports"]="nmap -p-"
    ["Service Detection|Detect service versions"]="nmap -sV"
    ["OS Detection|Detect operating system"]="sudo nmap -O"
    ["Aggressive Scan|OS, version, scripts, traceroute"]="sudo nmap -A"
    ["Stealth SYN Scan|Half-open scan (requires root)"]="sudo nmap -sS"
    ["UDP Scan|Scan UDP ports (slow)"]="sudo nmap -sU"
    ["Vulnerability Scan|Run vuln scripts"]="nmap --script vuln"
    ["Ping Scan|Host discovery only (no port scan)"]="nmap -sn"
    ["Fast Scan|Quick scan with version detection"]="nmap -T4 -F -sV"
)

# Use walker to select scan type
selected=$(printf '%s\n' "${!SCAN_PROFILES[@]}" |
    awk -F'|' '{printf "%-20s %s\n", $1, $2}' |
    walker --dmenu --prompt "🔍 Select Nmap Scan Type")

if [[ -z "$selected" ]]; then
    exit 0
fi

# Extract scan name
scan_name=$(echo "$selected" | awk '{print $1, $2}')

# Find the matching profile
scan_cmd=""
for key in "${!SCAN_PROFILES[@]}"; do
    if [[ "$key" == "$scan_name"* ]]; then
        scan_cmd="${SCAN_PROFILES[$key]}"
        break
    fi
done

if [[ -z "$scan_cmd" ]]; then
    notify-send "Nmap Error" "Could not find scan profile" -u critical
    exit 1
fi

# Get target from user
target=$(echo "" | walker --dmenu --prompt "🎯 Enter Target (IP/CIDR/hostname)")

if [[ -z "$target" ]]; then
    notify-send "Nmap" "Scan cancelled - no target specified" -u normal
    exit 0
fi

# Optional: Additional nmap flags
extra_flags=$(echo "" | walker --dmenu --prompt "⚙️  Extra Flags (optional, press Enter to skip)")

# Build full command
full_cmd="$scan_cmd $extra_flags $target"

# Show command preview and confirm
if echo -e "Command:\n$full_cmd\n\nProceed?" | walker --dmenu --prompt "⚠️  Confirm Scan"; then
    # Create output file
    output_file="/tmp/nmap-$(date +%Y%m%d-%H%M%S).txt"

    # Run scan in terminal
    $TERMINAL --class=omarchy-security-scan \
        --title="🔍 Nmap: $scan_name → $target" \
        -e bash -c "
            echo -e '${BLUE}╔═══════════════════════════════════════════════════════════════╗${NC}'
            echo -e '${BLUE}║${NC}                    ${GREEN}Nmap Security Scan${NC}                      ${BLUE}║${NC}'
            echo -e '${BLUE}╚═══════════════════════════════════════════════════════════════╝${NC}'
            echo ''
            echo -e '${YELLOW}Scan Type:${NC} $scan_name'
            echo -e '${YELLOW}Target:${NC}    $target'
            echo -e '${YELLOW}Command:${NC}   $full_cmd'
            echo -e '${YELLOW}Output:${NC}    $output_file'
            echo ''
            echo -e '${BLUE}Starting scan...${NC}'
            echo ''

            # Run scan with tee to save output
            $full_cmd | tee '$output_file'

            echo ''
            echo -e '${GREEN}═══════════════════════════════════════════════════════════════${NC}'
            echo -e '${GREEN}Scan complete!${NC}'
            echo -e 'Results saved to: ${YELLOW}$output_file${NC}'
            echo ''
            echo -e 'Options:'
            echo -e '  ${BLUE}[V]${NC} View in bat'
            echo -e '  ${BLUE}[E]${NC} Edit in \$EDITOR'
            echo -e '  ${BLUE}[C]${NC} Copy to clipboard'
            echo -e '  ${BLUE}[Q]${NC} Quit'
            echo ''
            read -n1 -p 'Choose action: ' action
            echo ''

            case \$action in
                v|V)
                    bat '$output_file'
                    ;;
                e|E)
                    \$EDITOR '$output_file'
                    ;;
                c|C)
                    wl-copy < '$output_file'
                    echo -e '${GREEN}✓${NC} Copied to clipboard'
                    sleep 1
                    ;;
            esac
        " &

    sleep 0.15
    hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security-scan$ >/dev/null 2>&1

    notify-send "🔍 Nmap Scan Started" "Target: $target\nScan: $scan_name" -u normal
else
    notify-send "Nmap" "Scan cancelled" -u normal
fi
