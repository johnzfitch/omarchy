#!/bin/bash
# Interactive Metasploit Launcher for Omarchy

TERMINAL="${TERMINAL:-ghostty}"

# Helper function to launch terminal on current workspace
launch_msf_terminal() {
    local title="$1"
    local cmd="$2"

    # Get current workspace
    local current_ws=$(hyprctl activeworkspace -j | jq -r '.id')

    # Launch terminal
    $TERMINAL --class=omarchy-security-msf --title="$title" -e bash -c "$cmd" &
    sleep 0.15

    # Tag and move to current workspace
    hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security-msf$ >/dev/null 2>&1
    hyprctl dispatch movetoworkspacesilent $current_ws,class:^omarchy-security-msf$ >/dev/null 2>&1
}

options=(
    "MSFConsole|Launch Metasploit console"
    "MSF Database|Initialize/manage database"
    "MSF Web UI|Launch Metasploit web interface"
    "Search Exploits|Search for exploits"
    "Recent Exploits|Show recently added exploits"
    "Payloads|List available payloads"
    "MSF Update|Update Metasploit framework"
)

selected=$(printf '%s\n' "${options[@]}" |
    awk -F'|' '{printf "%-20s %s\n", $1, $2}' |
    walker --dmenu --prompt "💀 Metasploit Framework")

if [[ -z "$selected" ]]; then
    exit 0
fi

action=$(echo "$selected" | awk '{print $1}')

case "$action" in
    "MSFConsole")
        launch_msf_terminal "💀 Metasploit Console" '
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║                  Metasploit Framework                          ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Starting msfconsole..."
            echo ""
            msfconsole
        '
        ;;

    "MSF")
        launch_msf_terminal "💀 Metasploit Database" '
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║                  Metasploit Database Setup                     ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Database Status:"
            sudo msfdb status
            echo ""
            echo "Options:"
            echo "  [I] Initialize database"
            echo "  [R] Reinitialize database"
            echo "  [D] Delete database"
            echo "  [S] Start database"
            echo "  [T] Stop database"
            echo "  [Q] Quit"
            echo ""
            read -n1 -p "Choose action: " choice
            echo ""
            echo ""

            case $choice in
                i|I)
                    echo "Initializing database..."
                    sudo msfdb init
                    ;;
                r|R)
                    echo "Reinitializing database..."
                    sudo msfdb reinit
                    ;;
                d|D)
                    echo "Deleting database..."
                    sudo msfdb delete
                    ;;
                s|S)
                    echo "Starting database..."
                    sudo msfdb start
                    ;;
                t|T)
                    echo "Stopping database..."
                    sudo msfdb stop
                    ;;
            esac

            echo ""
            echo "Current status:"
            sudo msfdb status
            echo ""
            read -p "Press Enter to exit..."
        '
        ;;

    "MSF")
        # Check if database is running first
        if ! sudo msfdb status | grep -q "running"; then
            notify-send "Metasploit" "Database not running. Initialize database first." -u critical
            exit 1
        fi

        launch_msf_terminal "💀 Metasploit Web UI" '
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║                  Metasploit Web Interface                      ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Starting Metasploit web service..."
            echo ""
            sudo msfdb start
            echo ""
            echo "Starting web UI on https://localhost:3790"
            echo ""
            echo "Default credentials:"
            echo "  Username: msf"
            echo "  Password: (generated on first run)"
            echo ""
            echo "Opening browser..."
            xdg-open https://localhost:3790 &
            echo ""
            read -p "Press Enter when done to stop service..."
            sudo systemctl stop metasploit
        '
        ;;

    "Search")
        search_term=$(echo "" | walker --dmenu --prompt "🔍 Search Exploits")
        if [[ -n "$search_term" ]]; then
            launch_msf_terminal "💀 Metasploit: Search Results" "
                echo 'Searching for: $search_term'
                echo ''
                msfconsole -q -x 'search $search_term; exit'
                echo ''
                read -p 'Press Enter to exit...'
            "
        fi
        ;;

    "Recent")
        launch_msf_terminal "💀 Metasploit: Recent Exploits" '
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║              Recently Added Exploits (Last 30 days)           ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            # Get date 30 days ago
            cutoff_date=$(date -d "30 days ago" +%Y-%m-%d)
            msfconsole -q -x "search cve:$cutoff_date- type:exploit; exit" | bat --paging=always --language=txt
        '
        ;;

    "Payloads")
        launch_msf_terminal "💀 Metasploit: Payloads" '
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║                  Available Payloads                            ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            msfconsole -q -x "show payloads; exit" | bat --paging=always --language=txt
        '
        ;;

    "MSF")
        launch_msf_terminal "💀 Metasploit: Update" '
            echo "╔═══════════════════════════════════════════════════════════════╗"
            echo "║                  Update Metasploit Framework                   ║"
            echo "╚═══════════════════════════════════════════════════════════════╝"
            echo ""
            echo "Updating via pacman..."
            sudo pacman -Sy metasploit
            echo ""
            echo "Update complete!"
            echo ""
            read -p "Press Enter to exit..."
        '
        ;;
esac
