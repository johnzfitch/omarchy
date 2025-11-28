#!/bin/bash
# Omarchy Security Toolkit Launcher
# Comprehensive security tools with icon support and wordlist integration

TERMINAL="${TERMINAL:-ghostty}"
EDITOR="${EDITOR:-nvim}"
WORDLIST_DIR="/home/zack/wordlists/SecLists"
FUZZDB_DIR="/home/zack/wordlists/fuzzdb"
ICON_DIR="/home/zack/dev/iconics/raw"
VPN_ROTATION="$HOME/.config/omarchy/scripts/vpn-rotation.sh"

# Helper function to launch terminal on current workspace
launch_terminal() {
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

# Security tool categories with icons and commands
declare -A TOOLS=(
    # VPN Controls
    ["🔄 VPN Auto-Rotate|Toggle automatic IP rotation"]="vpn_toggle"
    ["🌍 VPN Status|Show current VPN status and IP"]="vpn_status"
    ["🔀 Rotate IP Now|Manually rotate to new IP"]="vpn_rotate_now"

    # Network Scanning & Reconnaissance
    ["🔍 Nmap Scanner|Network port scanner and host discovery"]="$HOME/.config/omarchy/scripts/omarchy-security-nmap.sh"
    ["🌐 Masscan|Fast TCP port scanner"]="masscan_launcher"
    ["📡 Zenmap|Nmap GUI interface"]="zenmap"
    ["🗺️  Subfinder|Subdomain discovery tool"]="subfinder_launcher"

    # Web Application Testing
    ["🦊 Feroxbuster|Fast web content discovery"]="feroxbuster_launcher"
    ["🔥 FFuf|Fast web fuzzer"]="ffuf_launcher"
    ["📁 Gobuster|Directory/DNS/vhost brute-forcing"]="gobuster_launcher"
    ["💉 SQLMap|SQL injection & database takeover"]="sqlmap_launcher"

    # Exploitation & Post-Exploitation
    ["💀 Metasploit Console|Full Metasploit framework"]="$HOME/.config/omarchy/scripts/omarchy-security-metasploit.sh"
    ["🎯 Metasploit Search|Search exploits database"]="msf_search"

    # Password Cracking & Analysis
    ["🔓 John the Ripper|Password cracker"]="john_launcher"
    ["⚡ Hashcat|Advanced password recovery"]="hashcat_launcher"
    ["🌊 Hydra|Network login cracker"]="hydra_launcher"

    # Wireless Security
    ["📶 Aircrack-ng Suite|Wireless network security"]="aircrack_launcher"

    # Traffic Analysis
    ["🦈 Wireshark|Network protocol analyzer"]="wireshark"
    ["🔎 TShark|CLI network analyzer"]="tshark_launcher"

    # Wordlists & Resources
    ["📚 SecLists Browser|Browse SecLists wordlists"]="seclists_browser"
    ["🎯 FuzzDB Browser|Browse FuzzDB attack patterns"]="fuzzdb_browser"
    ["📖 Wordlist Manager|Manage wordlists"]="wordlist_manager"

    # OSINT & Reconnaissance
    ["🕵️  Sherlock|Username search across 300+ social networks"]="sherlock_launcher"
    ["🗺️  Smap|Passive Nmap-like port scanner"]="smap_launcher"
    ["🤖 Bbot|Advanced OSINT automation workflow engine"]="bbot_launcher"
    ["🌐 Whatweb|Web technology fingerprinting scanner"]="whatweb_launcher"
    ["🕷️  SpiderFoot|Comprehensive OSINT automation platform"]="spiderfoot_launcher"

    # System Security
    ["🛡️  Lynis|System security auditor"]="$HOME/.config/omarchy/scripts/omarchy-security-lynis.sh"

    # Utilities
    ["⚙️  Cod3x AI|OpenAI Codex CLI assistant"]="cod3x"
    ["🔧 Tool Updater|Update all security tools"]="tool_updater"
)

# Wordlist categories for quick access
declare -A WORDLISTS=(
    # SecLists
    ["SecLists: Passwords - Common"]="$WORDLIST_DIR/Passwords/Common-Credentials"
    ["SecLists: Passwords - Leaked"]="$WORDLIST_DIR/Passwords/Leaked-Databases"
    ["SecLists: Discovery - DNS"]="$WORDLIST_DIR/Discovery/DNS"
    ["SecLists: Discovery - Web Content"]="$WORDLIST_DIR/Discovery/Web-Content"
    ["SecLists: Fuzzing - Web"]="$WORDLIST_DIR/Fuzzing"
    ["SecLists: Usernames"]="$WORDLIST_DIR/Usernames"
    ["SecLists: Payloads - XSS"]="$WORDLIST_DIR/Payloads/XSS"
    ["SecLists: Payloads - SQLi"]="$WORDLIST_DIR/Payloads/SQL-Injection"

    # FuzzDB
    ["FuzzDB: Attack - XSS"]="$FUZZDB_DIR/attack/xss"
    ["FuzzDB: Attack - SQLi"]="$FUZZDB_DIR/attack/sql-injection"
    ["FuzzDB: Attack - LFI/RFI"]="$FUZZDB_DIR/attack/lfi"
    ["FuzzDB: Attack - Command Injection"]="$FUZZDB_DIR/attack/os-cmd-execution"
    ["FuzzDB: Attack - Path Traversal"]="$FUZZDB_DIR/attack/path-traversal"
    ["FuzzDB: Attack - NoSQL Injection"]="$FUZZDB_DIR/attack/no-sql-injection"
    ["FuzzDB: Discovery - Predictable"]="$FUZZDB_DIR/discovery/predictable-filepaths"
    ["FuzzDB: Wordlists - Usernames"]="$FUZZDB_DIR/wordlists-user-passwd/names"
    ["FuzzDB: Wordlists - Passwords"]="$FUZZDB_DIR/wordlists-user-passwd/passwds"
    ["FuzzDB: Web Backdoors"]="$FUZZDB_DIR/web-backdoors"
)

# Main launcher function
show_tool_menu() {
    local selected=$(printf '%s\n' "${!TOOLS[@]}" |
        awk -F'|' '{printf "%-35s │ %s\n", $1, $2}' |
        sort |
        walker --dmenu -p "🔐 Security Toolkit" --width 900 --maxheight 700)

    if [[ -z "$selected" ]]; then
        exit 0
    fi

    # Extract tool name
    local tool_name=$(echo "$selected" | awk -F'│' '{print $1}' | sed 's/[[:space:]]*$//')

    # Find matching command
    local tool_cmd=""
    for key in "${!TOOLS[@]}"; do
        if [[ "$key" == "$tool_name"* ]]; then
            tool_cmd="${TOOLS[$key]}"
            break
        fi
    done

    if [[ -z "$tool_cmd" ]]; then
        notify-send "Security Toolkit" "Tool not found" -u critical
        exit 1
    fi

    execute_tool "$tool_name" "$tool_cmd"
}

# Execute selected tool
execute_tool() {
    local name="$1"
    local cmd="$2"

    case "$cmd" in
        vpn_toggle)
            vpn_control_toggle
            ;;

        vpn_status)
            vpn_control_status
            ;;

        vpn_rotate_now)
            vpn_control_rotate
            ;;

        *.sh)
            # Execute omarchy script directly with VPN rotation
            execute_with_vpn "$name" "bash \"$cmd\""
            ;;

        masscan_launcher)
            launch_masscan
            ;;

        subfinder_launcher)
            launch_subfinder
            ;;

        feroxbuster_launcher)
            launch_feroxbuster
            ;;

        ffuf_launcher)
            launch_ffuf
            ;;

        gobuster_launcher)
            launch_gobuster
            ;;

        sqlmap_launcher)
            launch_sqlmap
            ;;

        john_launcher)
            launch_john
            ;;

        hashcat_launcher)
            launch_hashcat
            ;;

        hydra_launcher)
            launch_hydra
            ;;

        aircrack_launcher)
            launch_aircrack
            ;;

        tshark_launcher)
            launch_tshark
            ;;

        seclists_browser)
            browse_seclists
            ;;

        fuzzdb_browser)
            browse_fuzzdb
            ;;

        wordlist_manager)
            manage_wordlists
            ;;

        tool_updater)
            update_tools
            ;;

        msf_search)
            search_metasploit
            ;;

        sherlock_launcher)
            launch_sherlock
            ;;

        smap_launcher)
            launch_smap
            ;;

        bbot_launcher)
            launch_bbot
            ;;

        whatweb_launcher)
            launch_whatweb
            ;;

        spiderfoot_launcher)
            launch_spiderfoot
            ;;

        *)
            # Direct command execution
            launch_terminal "$name" "$cmd; exec bash"
            ;;
    esac
}

# VPN Rotation Functions

vpn_control_toggle() {
    "$VPN_ROTATION" toggle
    local status=$("$VPN_ROTATION" is-enabled)
    local current_ip=$("$VPN_ROTATION" get-ip)

    if [ "$status" = "yes" ]; then
        notify-send "VPN Auto-Rotation" "ENABLED\nCurrent IP: $current_ip" -u normal
    else
        notify-send "VPN Auto-Rotation" "DISABLED\nCurrent IP: $current_ip" -u normal
    fi
}

vpn_control_status() {
    launch_terminal "🌍 VPN Status" "
        echo '╔═══════════════════════════════════════════════════════════════╗'
        echo '║                       VPN Status                               ║'
        echo '╚═══════════════════════════════════════════════════════════════╝'
        echo ''
        '$VPN_ROTATION' status
        echo ''
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        mullvad status
        echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'
        echo ''
        read -p 'Press Enter to close...'
    "
}

vpn_control_rotate() {
    local old_ip=$("$VPN_ROTATION" get-ip)
    notify-send "VPN Rotation" "Rotating from $old_ip..." -u normal

    "$VPN_ROTATION" enable
    "$VPN_ROTATION" rotate

    local new_ip=$("$VPN_ROTATION" get-ip)
    notify-send "VPN Rotation" "Complete!\nOld: $old_ip\nNew: $new_ip" -u normal
}

# Execute tool with VPN rotation wrapper
execute_with_vpn() {
    local tool_name="$1"
    local tool_cmd="$2"

    # Check if rotation is enabled and rotate before launching
    if [ "$("$VPN_ROTATION" is-enabled)" = "yes" ]; then
        "$VPN_ROTATION" rotate
    fi

    # Launch tool with rotation prompt wrapper
    launch_terminal "$tool_name" "
        $tool_cmd
        '$VPN_ROTATION' prompt '$tool_name'
        exec bash
    "
}

# Tool launchers with wordlist integration

launch_feroxbuster() {
    local target=$(echo "" | walker --dmenu -p "🎯 Target URL (https://example.com)")
    if [[ -z "$target" ]]; then return; fi

    # Offer wordlist selection
    local wordlist=$(select_wordlist "Web Content")
    if [[ -z "$wordlist" ]]; then
        wordlist="$WORDLIST_DIR/Discovery/Web-Content/raft-large-words.txt"
    fi

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    launch_terminal "🦊 Feroxbuster: $target" "feroxbuster -u '$target' -w '$wordlist' -t 50; '$VPN_ROTATION' prompt 'Feroxbuster'; exec bash"
}

launch_ffuf() {
    local target=$(echo "" | walker --dmenu -p "🎯 Target URL (use FUZZ keyword)")
    if [[ -z "$target" ]]; then return; fi

    local wordlist=$(select_wordlist "Discovery")
    if [[ -z "$wordlist" ]]; then
        wordlist="$WORDLIST_DIR/Discovery/Web-Content/common.txt"
    fi

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    launch_terminal "🔥 FFuf: $target" "ffuf -u '$target' -w '$wordlist' -c; '$VPN_ROTATION' prompt 'FFuf'; exec bash"
}

launch_gobuster() {
    local mode=$(echo -e "dir|Directory brute-force\ndns|DNS subdomain\nvhost|Virtual host" |
        awk -F'|' '{printf "%-10s %s\n", $1, $2}' |
        walker --dmenu -p "Gobuster Mode")

    if [[ -z "$mode" ]]; then return; fi

    local target=$(echo "" | walker --dmenu -p "🎯 Target")
    if [[ -z "$target" ]]; then return; fi

    local mode_name=$(echo "$mode" | awk '{print $1}')
    local wordlist=$(select_wordlist "Discovery")

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    case "$mode_name" in
        dir)
            [[ -z "$wordlist" ]] && wordlist="$WORDLIST_DIR/Discovery/Web-Content/directory-list-2.3-medium.txt"
            launch_terminal "📁 Gobuster DIR: $target" "gobuster dir -u '$target' -w '$wordlist'; '$VPN_ROTATION' prompt 'Gobuster'; exec bash"
            ;;
        dns)
            [[ -z "$wordlist" ]] && wordlist="$WORDLIST_DIR/Discovery/DNS/subdomains-top1million-110000.txt"
            launch_terminal "🌐 Gobuster DNS: $target" "gobuster dns -d '$target' -w '$wordlist'; '$VPN_ROTATION' prompt 'Gobuster'; exec bash"
            ;;
        vhost)
            [[ -z "$wordlist" ]] && wordlist="$WORDLIST_DIR/Discovery/DNS/namelist.txt"
            launch_terminal "🌐 Gobuster VHOST: $target" "gobuster vhost -u '$target' -w '$wordlist'; '$VPN_ROTATION' prompt 'Gobuster'; exec bash"
            ;;
    esac
}

launch_subfinder() {
    local domain=$(echo "" | walker --dmenu -p "🌐 Domain")
    if [[ -z "$domain" ]]; then return; fi

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    launch_terminal "🗺️  Subfinder: $domain" "subfinder -d '$domain' -all -recursive; '$VPN_ROTATION' prompt 'Subfinder'; exec bash"
}

launch_masscan() {
    local target=$(echo "" | walker --dmenu -p "🎯 Target IP/CIDR")
    if [[ -z "$target" ]]; then return; fi

    local ports=$(echo "1-65535" | walker --dmenu -p "Ports (default: 1-65535)")
    [[ -z "$ports" ]] && ports="1-65535"

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    launch_terminal "🌐 Masscan: $target" "sudo masscan '$target' -p'$ports' --rate=10000; '$VPN_ROTATION' prompt 'Masscan'; exec bash"
}

launch_sqlmap() {
    local target=$(echo "" | walker --dmenu -p "🎯 Target URL")
    if [[ -z "$target" ]]; then return; fi

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    launch_terminal "💉 SQLMap: $target" "sqlmap -u '$target' --batch --banner; '$VPN_ROTATION' prompt 'SQLMap'; exec bash"
}

launch_john() {
    local hash_file=$(select_file "Select hash file")
    if [[ -z "$hash_file" ]]; then return; fi

    local wordlist=$(select_wordlist "Passwords")
    [[ -z "$wordlist" ]] && wordlist="$WORDLIST_DIR/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt"

    launch_terminal "🔓 John: $(basename $hash_file)" "john '$hash_file' --wordlist='$wordlist'; exec bash"
}

launch_hashcat() {
    local hash_file=$(select_file "Select hash file")
    if [[ -z "$hash_file" ]]; then return; fi

    local wordlist=$(select_wordlist "Passwords")
    [[ -z "$wordlist" ]] && wordlist="$WORDLIST_DIR/Passwords/Common-Credentials/10-million-password-list-top-1000000.txt"

    local mode=$(echo "" | walker --dmenu -p "Hash type (0=MD5, 1000=NTLM, etc.)")
    [[ -z "$mode" ]] && mode="0"

    launch_terminal "⚡ Hashcat: $(basename $hash_file)" "hashcat -m $mode '$hash_file' '$wordlist'; exec bash"
}

launch_hydra() {
    local target=$(echo "" | walker --dmenu -p "🎯 Target (IP or hostname)")
    if [[ -z "$target" ]]; then return; fi

    local service=$(echo -e "ssh\nftp\nhttp-post-form\nsmb\nmysql\npostgres" |
        walker --dmenu -p "Service")
    if [[ -z "$service" ]]; then return; fi

    local user_list=$(select_wordlist "Usernames")
    local pass_list=$(select_wordlist "Passwords")

    launch_terminal "🌊 Hydra: $service@$target" "hydra -L '$user_list' -P '$pass_list' '$target' '$service'; exec bash"
}

launch_aircrack() {
    launch_terminal "📶 Aircrack-ng Suite" '
        echo "╔═══════════════════════════════════════════════════════════════╗"
        echo "║                    Aircrack-ng Suite                           ║"
        echo "╚═══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Available tools:"
        echo "  airmon-ng    - Enable/disable monitor mode"
        echo "  airodump-ng  - Capture 802.11 frames"
        echo "  aireplay-ng  - Inject frames"
        echo "  aircrack-ng  - Crack WEP/WPA keys"
        echo ""
        read -p "Enter tool name: " tool
        echo ""
        $tool --help
        echo ""
        read -p "Enter command: " cmd
        eval "$tool $cmd"
        exec bash
    '
}

launch_tshark() {
    launch_terminal "🔎 TShark" "tshark -D; echo ''; read -p 'Interface number: ' iface; sudo tshark -i \$iface; exec bash"
}

# Wordlist helpers

select_wordlist() {
    local category="$1"
    local base_dir="$WORDLIST_DIR"

    # If category specified, navigate there
    if [[ "$category" == "Passwords" ]]; then
        base_dir="$WORDLIST_DIR/Passwords"
    elif [[ "$category" == "Discovery" ]]; then
        base_dir="$WORDLIST_DIR/Discovery"
    elif [[ "$category" == "Web Content" ]]; then
        base_dir="$WORDLIST_DIR/Discovery/Web-Content"
    fi

    # Find all wordlist files
    local wordlist=$(find "$base_dir" -type f \( -name "*.txt" -o -name "*.lst" \) 2>/dev/null |
        sed "s|$WORDLIST_DIR/||" |
        walker --dmenu -p "📚 Select Wordlist (or skip)" --width 800 --maxheight 600)

    if [[ -n "$wordlist" ]]; then
        echo "$WORDLIST_DIR/$wordlist"
    fi
}

browse_seclists() {
    local category=$(printf '%s\n' "${!WORDLISTS[@]}" | grep "^SecLists:" | sort |
        walker --dmenu -p "📚 SecLists Categories" --width 700)

    if [[ -z "$category" ]]; then return; fi

    local dir="${WORDLISTS[$category]}"

    if [[ -d "$dir" ]]; then
        launch_terminal "📚 SecLists: $category" "cd '$dir' && ls -lh && exec bash"
    fi
}

browse_fuzzdb() {
    local category=$(printf '%s\n' "${!WORDLISTS[@]}" | grep "^FuzzDB:" | sort |
        walker --dmenu -p "🎯 FuzzDB Categories" --width 700)

    if [[ -z "$category" ]]; then return; fi

    local dir="${WORDLISTS[$category]}"

    if [[ -d "$dir" ]]; then
        launch_terminal "🎯 FuzzDB: $category" "cd '$dir' && ls -lh && exec bash"
    fi
}

manage_wordlists() {
    local action=$(echo -e "Browse SecLists|Browse SecLists wordlists\nBrowse FuzzDB|Browse FuzzDB attack patterns\nUpdate SecLists|Update SecLists repository\nUpdate FuzzDB|Update FuzzDB repository\nCustom|Add custom wordlist\nSearch|Search wordlist content" |
        awk -F'|' '{printf "%-20s %s\n", $1, $2}' |
        walker --dmenu -p "📖 Wordlist Manager")

    case "$(echo $action | awk '{print $1, $2}')" in
        "Browse SecLists")
            nautilus "$WORDLIST_DIR" &
            ;;
        "Browse FuzzDB")
            nautilus "$FUZZDB_DIR" &
            ;;
        "Update SecLists")
            launch_terminal "📖 Update SecLists" "cd '$WORDLIST_DIR' && git pull; exec bash"
            ;;
        "Update FuzzDB")
            launch_terminal "🎯 Update FuzzDB" "cd '$FUZZDB_DIR' && git pull; exec bash"
            ;;
        Custom)
            local custom_dir="$HOME/wordlists/custom"
            mkdir -p "$custom_dir"
            nautilus "$custom_dir" &
            ;;
        Search)
            local query=$(echo "" | walker --dmenu -p "🔍 Search wordlists for...")
            if [[ -n "$query" ]]; then
                launch_terminal "🔍 Wordlist Search: $query" "
                    echo '=== Searching SecLists ==='
                    grep -r '$query' '$WORDLIST_DIR' 2>/dev/null | head -50
                    echo ''
                    echo '=== Searching FuzzDB ==='
                    grep -r '$query' '$FUZZDB_DIR' 2>/dev/null | head -50
                    exec bash
                "
            fi
            ;;
    esac
}

search_metasploit() {
    local query=$(echo "" | walker --dmenu -p "🔍 Search Metasploit")
    if [[ -z "$query" ]]; then return; fi

    launch_terminal "💀 MSF Search: $query" "msfconsole -q -x 'search $query; exit' | bat --paging=always; exec bash"
}

# OSINT Tool Launchers

launch_sherlock() {
    local username=$(echo "" | walker --dmenu -p "🕵️  Username to search")
    if [[ -z "$username" ]]; then return; fi

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    launch_terminal "🕵️  Sherlock: $username" "
        echo '╔═══════════════════════════════════════════════════════════════╗'
        echo '║                    Sherlock OSINT Search                       ║'
        echo '║          Username Search Across 300+ Networks                 ║'
        echo '╚═══════════════════════════════════════════════════════════════╝'
        echo ''
        echo 'Searching for: $username'
        echo ''
        sherlock '$username' --print-found
        echo ''
        echo 'Search complete!'
        '$VPN_ROTATION' prompt 'Sherlock'
        exec bash
    "
}

launch_smap() {
    local target=$(echo "" | walker --dmenu -p "🗺️  Target (IP or domain)")
    if [[ -z "$target" ]]; then return; fi

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    launch_terminal "🗺️  Smap: $target" "
        echo '╔═══════════════════════════════════════════════════════════════╗'
        echo '║                    Smap Passive Scanner                        ║'
        echo '║              Nmap-like Passive Reconnaissance                  ║'
        echo '╚═══════════════════════════════════════════════════════════════╝'
        echo ''
        smap '$target'
        echo ''
        echo 'Scan complete!'
        '$VPN_ROTATION' prompt 'Smap'
        exec bash
    "
}

launch_bbot() {
    local target=$(echo "" | walker --dmenu -p "🤖 Target (domain or IP)")
    if [[ -z "$target" ]]; then return; fi

    local scan_type=$(echo -e "subdomain-enum|Subdomain Enumeration\nweb-basic|Basic Web Scan\nweb-thorough|Thorough Web Scan\nemail-enum|Email Enumeration\ncloud-enum|Cloud Asset Discovery" |
        awk -F'|' '{printf "%-20s %s\n", $1, $2}' |
        walker --dmenu -p "🤖 Bbot Scan Type")

    if [[ -z "$scan_type" ]]; then return; fi

    local scan_name=$(echo "$scan_type" | awk '{print $1}')

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    launch_terminal "🤖 Bbot: $target" "
        echo '╔═══════════════════════════════════════════════════════════════╗'
        echo '║                    Bbot OSINT Engine                           ║'
        echo '║              Advanced Reconnaissance Automation                ║'
        echo '╚═══════════════════════════════════════════════════════════════╝'
        echo ''
        echo 'Target: $target'
        echo 'Scan: $scan_name'
        echo ''
        bbot -t '$target' -f '$scan_name'
        echo ''
        echo 'Scan complete!'
        '$VPN_ROTATION' prompt 'Bbot'
        exec bash
    "
}

launch_whatweb() {
    local target=$(echo "" | walker --dmenu -p "🌐 Target URL")
    if [[ -z "$target" ]]; then return; fi

    # Flag selection with descriptions
    local selected_flags=""
    local continue_selection=true

    while $continue_selection; do
        local current_flags_display=""
        if [[ -n "$selected_flags" ]]; then
            current_flags_display="Selected: $selected_flags"
        else
            current_flags_display="No flags selected (using defaults: -v verbose)"
        fi

        local flag_choice=$(echo -e "✓ Continue with current flags|$current_flags_display\n-a 1|Aggression Level 1: Stealthy (1 request, follows redirects)\n-a 3|Aggression Level 3: Aggressive (extra requests if match)\n-a 4|Aggression Level 4: Heavy (all plugin URLs attempted)\n--no-redirect|Don't follow redirects\n--user-agent|Custom user agent string\n--cookie|Add cookies (name=value format)\n-g|Grep for specific string/pattern in results\n--plugins|Select specific plugins to use\n--list-plugins|List all available plugins first\nCustom|Enter custom flags manually" |
            awk -F'|' '{printf "%-20s %s\n", $1, $2}' |
            walker --dmenu -p "🌐 WhatWeb Flags" --width 900 --maxheight 700)

        if [[ -z "$flag_choice" ]]; then
            return
        fi

        local flag=$(echo "$flag_choice" | awk '{print $1}')

        case "$flag" in
            "✓")
                continue_selection=false
                ;;
            "-a")
                local level=$(echo "$flag_choice" | awk '{print $2}')
                selected_flags="$selected_flags -a $level"
                ;;
            "--no-redirect")
                selected_flags="$selected_flags --follow-redirect=never"
                ;;
            "--user-agent")
                local ua=$(echo "" | walker --dmenu -p "User Agent String")
                if [[ -n "$ua" ]]; then
                    selected_flags="$selected_flags --user-agent '$ua'"
                fi
                ;;
            "--cookie")
                local cookie=$(echo "" | walker --dmenu -p "Cookie (name=value format)")
                if [[ -n "$cookie" ]]; then
                    selected_flags="$selected_flags --cookie '$cookie'"
                fi
                ;;
            "-g")
                local grep_pattern=$(echo "" | walker --dmenu -p "Grep pattern")
                if [[ -n "$grep_pattern" ]]; then
                    selected_flags="$selected_flags --grep '$grep_pattern'"
                fi
                ;;
            "--plugins")
                local plugins=$(echo "" | walker --dmenu -p "Plugin list (comma-separated)")
                if [[ -n "$plugins" ]]; then
                    selected_flags="$selected_flags --plugins '$plugins'"
                fi
                ;;
            "--list-plugins")
                launch_terminal "WhatWeb Plugins" "whatweb --list-plugins | less; exec bash"
                ;;
            "Custom")
                local custom=$(echo "" | walker --dmenu -p "Custom flags")
                if [[ -n "$custom" ]]; then
                    selected_flags="$selected_flags $custom"
                fi
                ;;
        esac
    done

    # Default to verbose if no flags selected
    if [[ -z "$selected_flags" ]]; then
        selected_flags="-v"
    fi

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    launch_terminal "🌐 Whatweb: $target" "
        echo '╔═══════════════════════════════════════════════════════════════╗'
        echo '║                Whatweb Technology Scanner                      ║'
        echo '║              Web Application Fingerprinting                    ║'
        echo '╚═══════════════════════════════════════════════════════════════╝'
        echo ''
        echo 'Target: $target'
        echo 'Flags: $selected_flags'
        echo ''
        if command -v whatweb &>/dev/null; then
            whatweb $selected_flags '$target'
        else
            echo 'Whatweb not installed. Install with: yay -S whatweb'
        fi
        echo ''
        echo 'Scan complete!'
        '$VPN_ROTATION' prompt 'Whatweb'
        exec bash
    "
}

launch_spiderfoot() {
    local mode=$(echo -e "web-ui|Launch Web UI (http://127.0.0.1:5001)\ncli|Command Line Interface" |
        awk -F'|' '{printf "%-10s %s\n", $1, $2}' |
        walker --dmenu -p "🕷️  SpiderFoot Mode")

    if [[ -z "$mode" ]]; then return; fi

    local mode_name=$(echo "$mode" | awk '{print $1}')

    # Rotate VPN if enabled
    [ "$("$VPN_ROTATION" is-enabled)" = "yes" ] && "$VPN_ROTATION" rotate

    case "$mode_name" in
        web-ui)
            launch_terminal "🕷️  SpiderFoot Web UI" "
                echo '╔═══════════════════════════════════════════════════════════════╗'
                echo '║              SpiderFoot OSINT Automation                       ║'
                echo '║                    Web Interface Mode                          ║'
                echo '╚═══════════════════════════════════════════════════════════════╝'
                echo ''
                echo 'Starting SpiderFoot Web UI...'
                echo 'Access at: http://127.0.0.1:5001'
                echo ''
                echo 'Press Ctrl+C to stop the server'
                echo ''
                spiderfoot -l 127.0.0.1:5001
                echo ''
                '$VPN_ROTATION' prompt 'SpiderFoot'
                exec bash
            "
            ;;
        cli)
            local target=$(echo "" | walker --dmenu -p "🎯 Target (domain, IP, email, etc.)")
            if [[ -z "$target" ]]; then return; fi

            local scan_type=$(echo -e "all|All modules\nfootprint|Footprinting\ninvestigate|Investigation\npassive|Passive only" |
                awk -F'|' '{printf "%-15s %s\n", $1, $2}' |
                walker --dmenu -p "🕷️  Scan Type")

            if [[ -z "$scan_type" ]]; then return; fi

            local scan_name=$(echo "$scan_type" | awk '{print $1}')

            # Flag selection with descriptions
            local selected_flags=""
            local continue_selection=true

            while $continue_selection; do
                local current_flags_display=""
                if [[ -n "$selected_flags" ]]; then
                    current_flags_display="Selected: $selected_flags"
                else
                    current_flags_display="No additional flags (using: -s -u $scan_name -o csv)"
                fi

                local flag_choice=$(echo -e "✓ Continue with current flags|$current_flags_display\n-d|Enable debug output\n-o json|Output JSON format instead of CSV\n-o tab|Output TAB format instead of CSV\n-H|Hide field headers (data only)\n-n|Strip newlines from data\n-r|Include source data field in output\n-x|STRICT MODE: Only direct modules for target\n-f|Filter to only requested event types\n-q|Disable logging (silent mode)\n-m|Specify modules to enable (comma-separated)\n-t|Event types to collect (comma-separated)\n-F|Show only specific event types\n--max-threads|Max concurrent modules\n-M|List available modules first\n-T|List event types first\nCustom|Enter custom flags manually" |
                    awk -F'|' '{printf "%-20s %s\n", $1, $2}' |
                    walker --dmenu -p "🕷️  SpiderFoot Flags" --width 900 --maxheight 700)

                if [[ -z "$flag_choice" ]]; then
                    return
                fi

                local flag=$(echo "$flag_choice" | awk '{print $1}')

                case "$flag" in
                    "✓")
                        continue_selection=false
                        ;;
                    "-d")
                        selected_flags="$selected_flags -d"
                        ;;
                    "-o")
                        local format=$(echo "$flag_choice" | awk '{print $2}')
                        # Remove existing -o flag if present
                        selected_flags=$(echo "$selected_flags" | sed 's/-o [a-z]*//g')
                        selected_flags="$selected_flags -o $format"
                        ;;
                    "-H")
                        selected_flags="$selected_flags -H"
                        ;;
                    "-n")
                        selected_flags="$selected_flags -n"
                        ;;
                    "-r")
                        selected_flags="$selected_flags -r"
                        ;;
                    "-x")
                        selected_flags="$selected_flags -x"
                        ;;
                    "-f")
                        selected_flags="$selected_flags -f"
                        ;;
                    "-q")
                        selected_flags="$selected_flags -q"
                        ;;
                    "-m")
                        local modules=$(echo "" | walker --dmenu -p "Module list (comma-separated)")
                        if [[ -n "$modules" ]]; then
                            selected_flags="$selected_flags -m '$modules'"
                        fi
                        ;;
                    "-t")
                        local types=$(echo "" | walker --dmenu -p "Event types (comma-separated)")
                        if [[ -n "$types" ]]; then
                            selected_flags="$selected_flags -t '$types'"
                        fi
                        ;;
                    "-F")
                        local filter_types=$(echo "" | walker --dmenu -p "Filter event types (comma-separated)")
                        if [[ -n "$filter_types" ]]; then
                            selected_flags="$selected_flags -F '$filter_types'"
                        fi
                        ;;
                    "--max-threads")
                        local threads=$(echo "" | walker --dmenu -p "Max threads (number)")
                        if [[ -n "$threads" ]]; then
                            selected_flags="$selected_flags --max-threads $threads"
                        fi
                        ;;
                    "-M")
                        launch_terminal "SpiderFoot Modules" "spiderfoot -M | less; exec bash"
                        ;;
                    "-T")
                        launch_terminal "SpiderFoot Event Types" "spiderfoot -T | less; exec bash"
                        ;;
                    "Custom")
                        local custom=$(echo "" | walker --dmenu -p "Custom flags")
                        if [[ -n "$custom" ]]; then
                            selected_flags="$selected_flags $custom"
                        fi
                        ;;
                esac
            done

            # Default output format if not specified
            if [[ ! "$selected_flags" =~ "-o" ]]; then
                selected_flags="$selected_flags -o csv"
            fi

            launch_terminal "🕷️  SpiderFoot CLI: $target" "
                echo '╔═══════════════════════════════════════════════════════════════╗'
                echo '║              SpiderFoot OSINT Automation                       ║'
                echo '║                Command Line Interface                          ║'
                echo '╚═══════════════════════════════════════════════════════════════╝'
                echo ''
                echo 'Target: $target'
                echo 'Scan Type: $scan_name'
                echo 'Flags: $selected_flags'
                echo ''
                spiderfoot -s '$target' -u '$scan_name' $selected_flags
                echo ''
                echo 'Scan complete!'
                '$VPN_ROTATION' prompt 'SpiderFoot'
                exec bash
            "
            ;;
    esac
}

update_tools() {
    launch_terminal "🔧 Tool Updater" '
        echo "╔═══════════════════════════════════════════════════════════════╗"
        echo "║                  Security Tools Updater                        ║"
        echo "╚═══════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Updating system packages..."
        sudo pacman -Sy
        echo ""
        echo "Updating Metasploit..."
        sudo pacman -S metasploit --needed
        echo ""
        echo "Updating SecLists..."
        cd ~/wordlists/SecLists && git pull
        echo ""
        echo "Update complete!"
        echo ""
        read -p "Press Enter to exit..."
    '
}

select_file() {
    local prompt="$1"
    local file=$(find ~ -type f -name "*" 2>/dev/null | walker --dmenu -p "$prompt" --width 800)
    echo "$file"
}

# Main
show_tool_menu "$@" </dev/null
