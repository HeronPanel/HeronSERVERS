#!/bin/bash
# =============================================================
#   HERON SERVER  -  Minecraft (PaperMC) Server Manager
# =============================================================

# ------------------------- COLORS ----------------------------
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
MAGENTA='\033[1;35m'
WHITE='\033[1;37m'
NC='\033[0m'

# ------------------------- PATHS ------------------------------
HERON_HOME="$HOME/.heron"
SERVERS_DIR="$HOME/HeronServers"
CONFIG_FILE="$HERON_HOME/config.cfg"

mkdir -p "$HERON_HOME"
mkdir -p "$SERVERS_DIR"

# Default settings (used if config file not present)
DEFAULT_RAM="2G"
DEFAULT_MIN_RAM="1G"
AUTO_EULA="true"

# Load config if exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    cat > "$CONFIG_FILE" <<EOF
DEFAULT_RAM="$DEFAULT_RAM"
DEFAULT_MIN_RAM="$DEFAULT_MIN_RAM"
AUTO_EULA="$AUTO_EULA"
SERVERS_DIR="$SERVERS_DIR"
EOF
fi

# ------------------------- BANNER ------------------------------
print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
██╗  ██╗███████╗██████╗  ██████╗ ███╗   ██╗
██║  ██║██╔════╝██╔══██╗██╔═══██╗████╗  ██║
███████║█████╗  ██████╔╝██║   ██║██╔██╗ ██║
██╔══██║██╔══╝  ██╔══██╗██║   ██║██║╚██╗██║
██║  ██║███████╗██║  ██║╚██████╔╝██║ ╚████║
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
EOF
    echo -e "${MAGENTA}"
    cat << "EOF"
███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗
██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗
███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝
╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗
███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║
╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
EOF
    echo -e "${NC}"
    echo -e "${YELLOW}          >> Minecraft (PaperMC) Server Manager <<${NC}"
    echo -e "${WHITE}------------------------------------------------------------${NC}"
}

pause() {
    echo ""
    read -rp "$(echo -e "${CYAN}Press ENTER to continue...${NC}")" _
}

# ------------------------- VERSION MAP --------------------------
declare -A VERSION_URLS
VERSION_URLS["1.21.11"]="https://fill-data.papermc.io/v1/objects/e708e8c132dc143ffd73528cccb9532e2eb17628b1a0eee74469bf466c7003f8/paper-1.21.11-116.jar"
VERSION_URLS["1.21.5"]="https://fill-data.papermc.io/v1/objects/2ae6ae22adf417699746e0f89fc2ef6cb6ee050a5f6608cee58f0535d60b509e/paper-1.21.5-114.jar"
VERSION_URLS["1.21.1"]="https://fill-data.papermc.io/v1/objects/39bd8c00b9e18de91dcabd3cc3dcfa5328685a53b7187a2f63280c22e2d287b9/paper-1.21.1-133.jar"
VERSION_URLS["1.21"]="https://fill-data.papermc.io/v1/objects/ab9bb1afc3cea6978a0c03ce8448aa654fe8a9c4dddf341e7cbda1b0edaa73f5/paper-1.21-130.jar"
VERSION_URLS["1.20"]="https://fill-data.papermc.io/v1/objects/1e4ccfc0599f491ee6fee4455d3722332ac5d78584fccd55cbb3b51e11504505/paper-1.20-17.jar"

# ------------------------- HELPERS -------------------------------

# Returns list of server names (folders inside SERVERS_DIR that contain server.jar)
list_servers() {
    local found=0
    if [ -d "$SERVERS_DIR" ]; then
        for d in "$SERVERS_DIR"/*/; do
            [ -d "$d" ] || continue
            local name
            name=$(basename "$d")
            echo "$name"
            found=1
        done
    fi
    if [ "$found" -eq 0 ]; then
        return 1
    fi
    return 0
}

select_server() {
    # prints numbered list, sets SELECTED_SERVER
    mapfile -t servers < <(list_servers)
    if [ ${#servers[@]} -eq 0 ]; then
        echo -e "${RED}No servers found! Use 'Create New Server' first.${NC}"
        SELECTED_SERVER=""
        return 1
    fi
    echo -e "${YELLOW}Available Servers:${NC}"
    local i=1
    for s in "${servers[@]}"; do
        echo -e "  ${GREEN}$i)${NC} $s"
        i=$((i+1))
    done
    echo ""
    read -rp "$(echo -e "${CYAN}Choose a server number: ${NC}")" idx
    if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ] || [ "$idx" -gt ${#servers[@]} ]; then
        echo -e "${RED}Invalid choice!${NC}"
        SELECTED_SERVER=""
        return 1
    fi
    SELECTED_SERVER="${servers[$((idx-1))]}"
    return 0
}

# ------------------------- CREATE SERVER ---------------------------
create_server() {
    print_banner
    echo -e "${GREEN}==== Create New Server ====${NC}"
    echo ""
    read -rp "$(echo -e "${CYAN}Server Name: ${NC}")" server_name

    if [ -z "$server_name" ]; then
        echo -e "${RED}Server name cannot be empty!${NC}"
        pause
        return
    fi

    # sanitize name (remove spaces/special chars)
    safe_name=$(echo "$server_name" | tr -cd '[:alnum:]_-')
    if [ -z "$safe_name" ]; then
        echo -e "${RED}Invalid server name!${NC}"
        pause
        return
    fi

    target_dir="$SERVERS_DIR/$safe_name"

    if [ -d "$target_dir" ]; then
        echo -e "${RED}A server with this name already exists!${NC}"
        pause
        return
    fi

    mkdir -p "$target_dir"
    cd "$target_dir" || { echo -e "${RED}Could not enter the folder!${NC}"; pause; return; }

    echo ""
    echo -e "${YELLOW}Choose Minecraft Version:${NC}"
    echo -e "  ${GREEN}1)${NC} 1.21.11  (Latest)"
    echo -e "  ${GREEN}2)${NC} 1.21.5"
    echo -e "  ${GREEN}3)${NC} 1.21.1"
    echo -e "  ${GREEN}4)${NC} 1.21"
    echo -e "  ${GREEN}5)${NC} 1.20"
    echo ""
    read -rp "$(echo -e "${CYAN}Choice (1-5): ${NC}")" vchoice

    case "$vchoice" in
        1) ver="1.21.11" ;;
        2) ver="1.21.5" ;;
        3) ver="1.21.1" ;;
        4) ver="1.21" ;;
        5) ver="1.20" ;;
        *) echo -e "${RED}Invalid choice, defaulting to 1.21.11.${NC}"; ver="1.21.11" ;;
    esac

    jar_url="${VERSION_URLS[$ver]}"

    echo ""
    echo -e "${YELLOW}Downloading PaperMC ${ver} server jar...${NC}"
    if command -v wget >/dev/null 2>&1; then
        wget -q --show-progress -O server.jar "$jar_url"
    else
        curl -L -o server.jar "$jar_url"
    fi

    if [ ! -s server.jar ]; then
        echo -e "${RED}Download failed! Check your internet connection.${NC}"
        pause
        return
    fi

    echo -e "${GREEN}Download complete!${NC}"

    # RAM settings
    echo ""
    read -rp "$(echo -e "${CYAN}Max RAM to allocate (default ${DEFAULT_RAM}, e.g. 2G/4G): ${NC}")" ram_input
    ram_input=${ram_input:-$DEFAULT_RAM}

    # eula.txt
    if [ "$AUTO_EULA" = "true" ]; then
        echo "eula=true" > eula.txt
    else
        echo "eula=false" > eula.txt
    fi

    # basic server.properties
    cat > server.properties <<EOP
server-port=25565
gamemode=survival
difficulty=easy
level-name=world
max-players=20
motd=\u00a7bHERON SERVER \u00a77- Powered by PaperMC ${ver}
online-mode=true
white-list=false
spawn-protection=0
EOP

    # start.sh for this server
    cat > start.sh <<EOS
#!/bin/bash
cd "\$(dirname "\$0")"
java -Xms${DEFAULT_MIN_RAM} -Xmx${ram_input} -jar server.jar nogui
EOS
    chmod +x start.sh

    # save meta info
    cat > .heron_meta <<EOM
NAME="$safe_name"
VERSION="$ver"
RAM="$ram_input"
CREATED="$(date '+%Y-%m-%d %H:%M:%S')"
EOM

    echo ""
    echo -e "${GREEN}✔ Server '${safe_name}' successfully created!${NC}"
    echo -e "${WHITE}   Location : $target_dir${NC}"
    echo -e "${WHITE}   Version  : $ver${NC}"
    echo -e "${WHITE}   RAM      : $ram_input${NC}"
    pause
}

# ------------------------- START SERVER ---------------------------
start_server() {
    print_banner
    echo -e "${GREEN}==== Start Server ====${NC}"
    echo ""
    select_server || { pause; return; }
    [ -z "$SELECTED_SERVER" ] && { pause; return; }

    dir="$SERVERS_DIR/$SELECTED_SERVER"
    if [ ! -f "$dir/server.jar" ]; then
        echo -e "${RED}server.jar not found for this server!${NC}"
        pause
        return
    fi

    if [ ! -f "$dir/start.sh" ]; then
        cat > "$dir/start.sh" <<EOS
#!/bin/bash
cd "\$(dirname "\$0")"
java -Xms${DEFAULT_MIN_RAM} -Xmx${DEFAULT_RAM} -jar server.jar nogui
EOS
        chmod +x "$dir/start.sh"
    fi

    echo -e "${YELLOW}Starting '${SELECTED_SERVER}' ... (Press CTRL+C or type 'stop' to shut down the server)${NC}"
    echo ""
    ( cd "$dir" && bash start.sh )
    pause
}

# ------------------------- DELETE SERVER ---------------------------
delete_server() {
    print_banner
    echo -e "${RED}==== Delete Server ====${NC}"
    echo ""
    select_server || { pause; return; }
    [ -z "$SELECTED_SERVER" ] && { pause; return; }

    echo ""
    read -rp "$(echo -e "${RED}Are you sure you want to delete '$SELECTED_SERVER'? This is permanent! (yes/no): ${NC}")" confirm
    if [ "$confirm" = "yes" ]; then
        rm -rf "${SERVERS_DIR:?}/${SELECTED_SERVER:?}"
        echo -e "${GREEN}✔ Server '$SELECTED_SERVER' has been deleted.${NC}"
    else
        echo -e "${YELLOW}Delete cancelled.${NC}"
    fi
    pause
}

# ------------------------- RENAME SERVER ---------------------------
rename_server() {
    print_banner
    echo -e "${BLUE}==== Rename Server ====${NC}"
    echo ""
    select_server || { pause; return; }
    [ -z "$SELECTED_SERVER" ] && { pause; return; }

    read -rp "$(echo -e "${CYAN}Enter new name: ${NC}")" new_name
    new_safe=$(echo "$new_name" | tr -cd '[:alnum:]_-')

    if [ -z "$new_safe" ]; then
        echo -e "${RED}Invalid name!${NC}"
        pause
        return
    fi

    if [ -d "$SERVERS_DIR/$new_safe" ]; then
        echo -e "${RED}A server with this name already exists!${NC}"
        pause
        return
    fi

    mv "$SERVERS_DIR/$SELECTED_SERVER" "$SERVERS_DIR/$new_safe"
    echo -e "${GREEN}✔ Server '$SELECTED_SERVER' has been renamed to '$new_safe'.${NC}"
    pause
}

# ------------------------- UNINSTALL SERVER (full remove) ---------------------------
uninstall_server() {
    print_banner
    echo -e "${RED}==== Uninstall Server ====${NC}"
    echo -e "${YELLOW}This option will completely remove all files for a server${NC}"
    echo -e "${YELLOW}(world, plugins, jar, configs) - as if it never existed.${NC}"
    echo ""
    select_server || { pause; return; }
    [ -z "$SELECTED_SERVER" ] && { pause; return; }

    echo ""
    read -rp "$(echo -e "${RED}FINAL WARNING: Fully uninstall '$SELECTED_SERVER'? (type UNINSTALL): ${NC}")" confirm
    if [ "$confirm" = "UNINSTALL" ]; then
        rm -rf "${SERVERS_DIR:?}/${SELECTED_SERVER:?}"
        echo -e "${GREEN}✔ Server '$SELECTED_SERVER' has been completely uninstalled.${NC}"
    else
        echo -e "${YELLOW}Uninstall cancelled (exact word 'UNINSTALL' not entered).${NC}"
    fi
    pause
}

# ------------------------- SETTINGS ---------------------------
settings_menu() {
    while true; do
        print_banner
        echo -e "${MAGENTA}==== Settings ====${NC}"
        echo ""
        echo -e "  ${GREEN}1)${NC} Default Max RAM        : ${WHITE}${DEFAULT_RAM}${NC}"
        echo -e "  ${GREEN}2)${NC} Default Min RAM        : ${WHITE}${DEFAULT_MIN_RAM}${NC}"
        echo -e "  ${GREEN}3)${NC} Auto-accept EULA       : ${WHITE}${AUTO_EULA}${NC}"
        echo -e "  ${GREEN}4)${NC} Servers Directory      : ${WHITE}${SERVERS_DIR}${NC}"
        echo -e "  ${GREEN}5)${NC} Back to Main Menu"
        echo ""
        read -rp "$(echo -e "${CYAN}Choice: ${NC}")" schoice
        case "$schoice" in
            1)
                read -rp "$(echo -e "${CYAN}New Max RAM (e.g. 4G): ${NC}")" val
                [ -n "$val" ] && DEFAULT_RAM="$val"
                ;;
            2)
                read -rp "$(echo -e "${CYAN}New Min RAM (e.g. 1G): ${NC}")" val
                [ -n "$val" ] && DEFAULT_MIN_RAM="$val"
                ;;
            3)
                read -rp "$(echo -e "${CYAN}Auto-accept EULA? (true/false): ${NC}")" val
                [ -n "$val" ] && AUTO_EULA="$val"
                ;;
            4)
                read -rp "$(echo -e "${CYAN}New servers directory path: ${NC}")" val
                if [ -n "$val" ]; then
                    mkdir -p "$val"
                    SERVERS_DIR="$val"
                fi
                ;;
            5) break ;;
            *) echo -e "${RED}Invalid choice!${NC}"; sleep 1 ;;
        esac
        # save config after every change
        cat > "$CONFIG_FILE" <<EOF
DEFAULT_RAM="$DEFAULT_RAM"
DEFAULT_MIN_RAM="$DEFAULT_MIN_RAM"
AUTO_EULA="$AUTO_EULA"
SERVERS_DIR="$SERVERS_DIR"
EOF
    done
}

# ------------------------- MAIN MENU ---------------------------
main_menu() {
    while true; do
        print_banner
        echo -e "${WHITE}  1)${NC} Create New Server"
        echo -e "${WHITE}  2)${NC} Start Server"
        echo -e "${WHITE}  3)${NC} Delete Server"
        echo -e "${WHITE}  4)${NC} Rename Server"
        echo -e "${WHITE}  5)${NC} Uninstall Server"
        echo -e "${WHITE}  6)${NC} Settings"
        echo -e "${WHITE}  7)${NC} Exit"
        echo -e "${WHITE}------------------------------------------------------------${NC}"
        read -rp "$(echo -e "${CYAN}Enter your choice (1-7): ${NC}")" choice

        case "$choice" in
            1) create_server ;;
            2) start_server ;;
            3) delete_server ;;
            4) rename_server ;;
            5) uninstall_server ;;
            6) settings_menu ;;
            7)
                echo -e "${GREEN}Thank you! Shutting down HERON SERVER...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice, try again!${NC}"
                sleep 1
                ;;
        esac
    done
}

# ------------------------- ENTRY POINT ---------------------------
if ! command -v java >/dev/null 2>&1; then
    echo -e "${RED}WARNING: Java is not installed! Java (17+) is required to run the server.${NC}"
    echo -e "${YELLOW}Install: sudo apt install openjdk-21-jre-headless -y${NC}"
    sleep 3
fi

main_menu
