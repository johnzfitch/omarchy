#!/bin/bash
# Mullvad VPN Rotation Module for Omarchy Security Toolkit
# Handles automatic IP rotation for security operations

VPN_STATE_FILE="$HOME/.cache/omarchy-vpn-rotation.state"
VPN_LOG_FILE="$HOME/.local/share/omarchy-vpn-rotation.log"

mkdir -p "$(dirname "$VPN_STATE_FILE")"
mkdir -p "$(dirname "$VPN_LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$VPN_LOG_FILE"
}

notify() {
    notify-send "VPN Rotation" "$*" -u low -t 3000
    log "$*"
}

# Get current VPN status
get_vpn_status() {
    mullvad status 2>/dev/null | grep -q "Connected" && echo "connected" || echo "disconnected"
}

# Get current IP
get_current_ip() {
    mullvad status 2>/dev/null | grep -oP 'IPv4: \K[\d.]+' || echo "unknown"
}

# Check if rotation is enabled
is_rotation_enabled() {
    [[ -f "$VPN_STATE_FILE" ]] && [[ "$(cat "$VPN_STATE_FILE")" == "enabled" ]]
}

# Enable rotation
enable_rotation() {
    echo "enabled" > "$VPN_STATE_FILE"
    notify "VPN Rotation: ENABLED"
    log "Rotation enabled"
}

# Disable rotation
disable_rotation() {
    rm -f "$VPN_STATE_FILE"
    notify "VPN Rotation: DISABLED"
    log "Rotation disabled"
}

# Toggle rotation
toggle_rotation() {
    if is_rotation_enabled; then
        disable_rotation
    else
        enable_rotation
    fi
}

# Rotate to new server
rotate_server() {
    if ! is_rotation_enabled; then
        log "Rotation disabled, skipping"
        return 0
    fi

    local current_ip
    current_ip=$(get_current_ip)

    notify "Rotating VPN... (Current: $current_ip)"
    log "Rotating from IP: $current_ip"

    # Reconnect to get different server
    mullvad reconnect >/dev/null 2>&1

    # Wait for connection
    sleep 3

    # Verify new IP
    local new_ip
    new_ip=$(get_current_ip)

    if [ "$current_ip" != "$new_ip" ]; then
        notify "Rotated to: $new_ip"
        log "Successfully rotated to: $new_ip"
    else
        # Try switching relay location if same IP
        log "Same IP detected, switching relay location"
        mullvad relay set location us >/dev/null 2>&1
        mullvad reconnect >/dev/null 2>&1
        sleep 3
        new_ip=$(get_current_ip)
        notify "Rotated to: $new_ip"
        log "Rotated to: $new_ip after relay switch"
    fi

    # Random delay to simulate human behavior (2-5 seconds)
    local delay=$((2 + RANDOM % 4))
    sleep "$delay"
}

# Show VPN status
show_status() {
    local status=$(get_vpn_status)
    local ip=$(get_current_ip)
    local rotation_status

    if is_rotation_enabled; then
        rotation_status="ENABLED"
    else
        rotation_status="DISABLED"
    fi

    echo "VPN Status: $status"
    echo "Current IP: $ip"
    echo "Auto-Rotation: $rotation_status"
}

# Prompt user after tool completion
prompt_disable() {
    local tool_name="$1"

    if ! is_rotation_enabled; then
        return 0
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "VPN Auto-Rotation is currently ENABLED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    read -p "Do you want to disable VPN rotation? (y/N): " response

    case "$response" in
        [yY]|[yY][eE][sS])
            disable_rotation
            echo "VPN rotation disabled."
            ;;
        *)
            echo "VPN rotation remains enabled."
            ;;
    esac
}

# Main command dispatcher
case "${1:-status}" in
    enable)
        enable_rotation
        ;;
    disable)
        disable_rotation
        ;;
    toggle)
        toggle_rotation
        ;;
    rotate)
        rotate_server
        ;;
    status)
        show_status
        ;;
    is-enabled)
        is_rotation_enabled && echo "yes" || echo "no"
        ;;
    prompt)
        prompt_disable "$2"
        ;;
    get-ip)
        get_current_ip
        ;;
    *)
        echo "Usage: $0 {enable|disable|toggle|rotate|status|is-enabled|prompt|get-ip}"
        exit 1
        ;;
esac
