#!/bin/bash
# Interactive Lynis Auditor for Omarchy
# TUI wrapper for Lynis security auditing

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

# Menu options
options=(
    "Full System Audit|Complete security audit of the system"
    "Quick Audit|Fast scan skipping some tests"
    "View Last Report|Show results from previous audit"
    "Show Warnings|Display only warnings from last audit"
    "Show Suggestions|Display security suggestions"
    "Update Lynis|Update Lynis database"
    "System Hardening Index|Show security score"
)

selected=$(printf '%s\n' "${options[@]}" |
    awk -F'|' '{printf "%-25s %s\n", $1, $2}' |
    walker --dmenu --prompt "🛡️ Lynis Security Audit")

if [[ -z "$selected" ]]; then
    exit 0
fi

action=$(echo "$selected" | awk '{print $1, $2}')

case "$action" in
    "Full System"|"Full System Audit")
        $TERMINAL --class=omarchy-security-audit \
            --title="🛡️ Lynis: Full System Audit" \
            -e bash -c '
                echo "╔═══════════════════════════════════════════════════════════════╗"
                echo "║              Lynis Full System Security Audit                 ║"
                echo "╚═══════════════════════════════════════════════════════════════╝"
                echo ""
                echo "This will perform a comprehensive security audit."
                echo "The scan may take several minutes."
                echo ""
                read -p "Press Enter to start audit..."

                sudo lynis audit system

                echo ""
                echo "═══════════════════════════════════════════════════════════════"
                echo "Audit complete!"
                echo ""
                echo "Report saved to: /var/log/lynis-report.dat"
                echo "Full log: /var/log/lynis.log"
                echo ""
                read -p "Press Enter to exit..."
            ' &
        sleep 0.15
        hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security-audit$ >/dev/null 2>&1
        ;;

    "Quick Audit"|"Quick Audit Fast")
        $TERMINAL --class=omarchy-security-audit \
            --title="🛡️ Lynis: Quick Audit" \
            -e bash -c '
                sudo lynis audit system --quick
                echo ""
                read -p "Press Enter to exit..."
            ' &
        sleep 0.15
        hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security-audit$ >/dev/null 2>&1
        ;;

    "View Last"|"View Last Report")
        if [[ -f /var/log/lynis.log ]]; then
            $TERMINAL --class=omarchy-security-audit \
                --title="🛡️ Lynis: Last Report" \
                -e bat --paging=always --style=numbers,grid /var/log/lynis.log &
            sleep 0.15
            hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security-audit$ >/dev/null 2>&1
        else
            notify-send "Lynis" "No previous report found. Run an audit first." -u normal
        fi
        ;;

    "Show Warnings"|"Show Warnings Display")
        if [[ -f /var/log/lynis-report.dat ]]; then
            $TERMINAL --class=omarchy-security-audit \
                --title="🛡️ Lynis: Warnings" \
                -e bash -c '
                    echo "╔═══════════════════════════════════════════════════════════════╗"
                    echo "║                   Lynis Security Warnings                      ║"
                    echo "╚═══════════════════════════════════════════════════════════════╝"
                    echo ""
                    grep "warning=" /var/log/lynis-report.dat | sed "s/warning=//" | bat --paging=always --language=txt --style=plain
                    echo ""
                    read -p "Press Enter to exit..."
                ' &
            sleep 0.15
            hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security-audit$ >/dev/null 2>&1
        else
            notify-send "Lynis" "No report found. Run an audit first." -u normal
        fi
        ;;

    "Show Suggestions"|"Show Suggestions Display")
        if [[ -f /var/log/lynis-report.dat ]]; then
            $TERMINAL --class=omarchy-security-audit \
                --title="🛡️ Lynis: Security Suggestions" \
                -e bash -c '
                    echo "╔═══════════════════════════════════════════════════════════════╗"
                    echo "║                 Lynis Security Suggestions                     ║"
                    echo "╚═══════════════════════════════════════════════════════════════╝"
                    echo ""
                    grep "suggestion=" /var/log/lynis-report.dat | sed "s/suggestion=//" | bat --paging=always --language=txt --style=plain
                    echo ""
                    read -p "Press Enter to exit..."
                ' &
            sleep 0.15
            hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security-audit$ >/dev/null 2>&1
        else
            notify-send "Lynis" "No report found. Run an audit first." -u normal
        fi
        ;;

    "Update Lynis"|"Update Lynis Update")
        $TERMINAL --class=omarchy-security-audit \
            --title="🛡️ Lynis: Update" \
            -e bash -c '
                echo "Updating Lynis database..."
                sudo lynis update info
                echo ""
                read -p "Press Enter to exit..."
            ' &
        sleep 0.15
        hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security-audit$ >/dev/null 2>&1
        ;;

    "System Hardening"|"System Hardening Index")
        if [[ -f /var/log/lynis-report.dat ]]; then
            $TERMINAL --class=omarchy-security-audit \
                --title="🛡️ Lynis: Hardening Index" \
                -e bash -c '
                    echo "╔═══════════════════════════════════════════════════════════════╗"
                    echo "║                System Hardening Index                          ║"
                    echo "╚═══════════════════════════════════════════════════════════════╝"
                    echo ""
                    hardening_index=$(grep "hardening_index=" /var/log/lynis-report.dat | cut -d= -f2)
                    echo "Security Score: $hardening_index"
                    echo ""
                    echo "Score Guide:"
                    echo "  0-25:   ⚠️  Poor - Immediate attention required"
                    echo "  26-50:  ⚡ Fair - Several improvements needed"
                    echo "  51-75:  ✓  Good - Some hardening recommended"
                    echo "  76-100: ✓✓ Excellent - Well hardened system"
                    echo ""
                    read -p "Press Enter to view full suggestions..."
                    grep "suggestion=" /var/log/lynis-report.dat | sed "s/suggestion=//" | bat --paging=always --language=txt --style=plain
                ' &
            sleep 0.15
            hyprctl dispatch tagwindow +omarchy-security class:^omarchy-security-audit$ >/dev/null 2>&1
        else
            notify-send "Lynis" "No report found. Run an audit first." -u normal
        fi
        ;;
esac
