#!/bin/bash

# --- Utility Functions ---
print_error() {
    echo "==============================="
    echo "❌ $1"
    echo "==============================="
}

# Check Ubuntu version and exit if not 24.04
# Try different locations for lsb-release file
if [ -f "/etc/upstream-release/lsb-release" ]; then
    DISTRIB_RELEASE=$(grep DISTRIB_RELEASE /etc/upstream-release/lsb-release | cut -d= -f2)
elif [ -f "/etc/lsb-release" ]; then
    DISTRIB_RELEASE=$(grep DISTRIB_RELEASE /etc/lsb-release | cut -d= -f2)
else
    # Fallback to lsb_release command if available
    if command -v lsb_release &> /dev/null; then
        DISTRIB_RELEASE=$(lsb_release -r | cut -f2)
    else
        print_error "Cannot determine Ubuntu version. Please ensure this is Ubuntu 24.04."
        exit 1
    fi
fi

if [ "$DISTRIB_RELEASE" != "24.04" ]; then
    echo "-------------------------------------"
    echo "==============================="
    echo "❌ This script is for Ubuntu 24.04 only."
    echo "==============================="
    echo "You are running Ubuntu $DISTRIB_RELEASE."
    echo "This script is for Ubuntu 24.04 only."
    echo "Please use the installer for Ubuntu 22.04:"
    echo "https://github.com/hieutt192/Cursor-ubuntu/tree/main"
    echo "-------------------------------------"
    exit 1
fi

# --- Global Variables ---
CURSOR_EXTRACT_DIR="/opt/Cursor"                   # Where the AppImage is extracted
ICON_FILENAME_ON_DISK="cursor-icon.png"            # Main icon name
ALT_ICON_FILENAME_ON_DISK="cursor-black-icon.png"  # Secondary icon (dark variant)
ICON_PATH="${CURSOR_EXTRACT_DIR}/${ICON_FILENAME_ON_DISK}"
EXECUTABLE_PATH="${CURSOR_EXTRACT_DIR}/AppRun"     # Main executable after extract
DESKTOP_ENTRY_PATH="/usr/share/applications/cursor.desktop"

# --- Utility Functions ---
print_success() {
    echo "==============================="
    echo "✅ $1"
    echo "==============================="
}

print_info() {
    echo "==============================="
    echo "ℹ️ $1"
    echo "==============================="
}

# --- Dependency Management ---
install_dependencies() {
    local deps=("curl" "jq" "wget" "figlet")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "📦 $dep is not installed. Installing..."
            sudo apt-get update
            sudo apt-get install -y "$dep"
        fi
    done
}

# --- Download Latest Cursor AppImage Function ---
download_latest_cursor_appimage() {
    API_URL="https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=stable"
    USER_AGENT="Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    DOWNLOAD_PATH="/tmp/latest-cursor.AppImage"

    FINAL_URL=$(curl -sL -A "$USER_AGENT" "$API_URL" | jq -r '.url // .downloadUrl')
    if [ -z "$FINAL_URL" ] || [ "$FINAL_URL" = "null" ]; then
        print_error "Could not retrieve the final AppImage URL from the Cursor API."
        return 1
    fi

    echo "⬇️ Downloading latest Cursor AppImage from: $FINAL_URL"
    wget -q -O "$DOWNLOAD_PATH" "$FINAL_URL"
    if [ $? -eq 0 ] && [ -s "$DOWNLOAD_PATH" ]; then
        echo "✅ Successfully downloaded the Cursor AppImage!"
        echo "$DOWNLOAD_PATH"
        return 0
    else
        print_error "Failed to download the AppImage."
        return 1
    fi
}

# --- Download Functions ---
get_appimage_path() {
    local operation="$1"  # "install" or "update"
    local action_text=""
    
    if [ "$operation" = "update" ]; then
        action_text="new Cursor AppImage"
    else
        action_text="Cursor AppImage"
    fi
    
    echo "⬇️ Automatically downloading the latest ${action_text}..." >&2
    local cursor_download_path=""
    
    # Try auto-download first
    cursor_download_path=$(download_latest_cursor_appimage 2>/dev/null | tail -n 1)
    
    if [ $? -eq 0 ] && [ -f "$cursor_download_path" ]; then
        echo "✅ Auto-download successful!" >&2
        # Return the auto-downloaded path
        echo "$cursor_download_path"
        return 0
    else
        print_error "Auto-download failed!" >&2
        echo "" >&2
        echo "📋 Don't worry! Let's try manual download instead:" >&2
        echo "1. Visit: https://cursor.sh" >&2
        echo "2. Download the Cursor AppImage file for Linux" >&2
        echo "3. Provide the full path to the downloaded .AppImage file below" >&2
        echo "" >&2
        echo "⚠️ Important: Please provide a .AppImage file, NOT an icon file (.png)" >&2
        echo "" >&2
        
        # Get manual path with validation loop
        while true; do
            if [ "$operation" = "update" ]; then
                read -rp "📂 Enter the full path to your downloaded Cursor AppImage: " cursor_download_path >&2
            else
                read -rp "📂 Enter the full path to your downloaded Cursor AppImage: " cursor_download_path >&2
            fi
            
            # Validate the manual path
            if [ -f "$cursor_download_path" ] && [[ "$cursor_download_path" =~ \.AppImage$ ]]; then
                echo "✅ Valid AppImage file found!" >&2
                break
            elif [ ! -f "$cursor_download_path" ]; then
                echo "❌ File not found. Please check the path and try again." >&2
            elif [[ ! "$cursor_download_path" =~ \.AppImage$ ]]; then
                echo "❌ Invalid file type. Please provide a .AppImage file, not: $(basename "$cursor_download_path")" >&2
            else
                echo "❌ Unknown error. Please try again." >&2
            fi
            
            echo "Do you want to try another path? (y/n)" >&2
            read -r retry_choice >&2
            if [[ ! "$retry_choice" =~ ^[Yy]$ ]]; then
                print_error "Installation cancelled by user." >&2
                exit 1
            fi
        done
        
        # Return the manually entered path
        echo "$cursor_download_path"
        return 0
    fi
}

# --- AppImage Processing ---
process_appimage() {
    local source_path="$1"
    local operation="$2"  # "install" or "update"

    if [ ! -f "$source_path" ]; then
        print_error "File does not exist at: $source_path"
        exit 1
    fi

    chmod +x "$source_path"
    echo "📦 Extracting AppImage..."
    (cd /tmp && "$source_path" --appimage-extract > /dev/null)
    if [ ! -d "/tmp/squashfs-root" ]; then
        print_error "Failed to extract the AppImage."
        sudo rm -f "$source_path"
        exit 1
    fi
    echo "✅ Extraction successful!"

    if [ "$operation" = "update" ]; then
        # ── Preserve icon(s) ────────────────────────────────
        local icon_backup_dir="/tmp/cursor_icon_backup.$$"
        mkdir -p "$icon_backup_dir"
        for icon_file in "$ICON_FILENAME_ON_DISK" "$ALT_ICON_FILENAME_ON_DISK"; do
            if [ -f "${CURSOR_EXTRACT_DIR}/${icon_file}" ]; then
                cp "${CURSOR_EXTRACT_DIR}/${icon_file}" "${icon_backup_dir}/"
            fi
        done

        echo "🗑️ Removing old version at ${CURSOR_EXTRACT_DIR}..."
        sudo rm -rf "${CURSOR_EXTRACT_DIR:?}"/*
    else
        echo "📁 Creating installation directory at ${CURSOR_EXTRACT_DIR}..."
        sudo mkdir -p "$CURSOR_EXTRACT_DIR"
    fi

    echo "📦 Deploying new version..."
    sudo rsync -a --remove-source-files /tmp/squashfs-root/ "$CURSOR_EXTRACT_DIR/"

    if [ "$operation" = "update" ]; then
        # ── Restore icon(s) ────────────────────────────────
        for icon_file in "$ICON_FILENAME_ON_DISK" "$ALT_ICON_FILENAME_ON_DISK"; do
            if [ -f "${icon_backup_dir}/${icon_file}" ]; then
                sudo mv "${icon_backup_dir}/${icon_file}" "${CURSOR_EXTRACT_DIR}/${icon_file}"
            fi
        done
        rm -rf "$icon_backup_dir"
    fi

    echo "🔧 Setting proper permissions..."
    # Set directory permissions (755 = rwxr-xr-x)
    sudo chmod -R 755 "$CURSOR_EXTRACT_DIR"
    # Ensure executable is properly set
    sudo chmod +x "$EXECUTABLE_PATH"
    if [ $? -ne 0 ]; then
        print_error "Failed to set permissions. Please check system configuration."
        exit 1
    fi
    echo "✅ Permissions set successfully."

    sudo rm -f "$source_path"
    sudo rm -rf /tmp/squashfs-root
}
# --- Installation Function ---
installCursor() {
    if [ -d "$CURSOR_EXTRACT_DIR" ]; then
        print_info "Cursor is already installed at $CURSOR_EXTRACT_DIR. Choose the Update option instead."
        exec "$0"
    fi

    figlet -f slant "Install Cursor"
    echo "💿 Installing Cursor AI IDE on Ubuntu..."

    install_dependencies

    local cursor_download_path=$(get_appimage_path "install")

    process_appimage "$cursor_download_path" "install"

    # ── Icon & desktop entry ───────────────────────────────────────────────
    echo "Available icons:"
    echo "1. cursor-icon.png - Standard Cursor logo with blue background"
    echo "2. cursor-black-icon.png - Cursor logo with dark/black background"
    echo "Note: Only these 2 icons are currently available."
    echo "------------------------"
    while true; do
        read -rp "🎨 Enter icon filename (cursor-icon.png or cursor-black-icon.png): " icon_name_from_github
        
        # Validate icon filename
        if [ -z "$icon_name_from_github" ]; then
            echo "❌ No icon filename provided. Please try again."
            continue
        elif [[ ! "$icon_name_from_github" =~ \.(png|jpg|jpeg|svg)$ ]]; then
            echo "❌ Invalid file type. Please provide an image file (.png, .jpg, .jpeg, .svg)."
            continue
        fi
        
        local icon_download_url="https://raw.githubusercontent.com/hieutt192/Cursor-ubuntu/Cursor-ubuntu24.04/images/$icon_name_from_github"
        echo "🎨 Downloading icon to $ICON_PATH..."
        
        # Try to download icon with error handling
        if sudo curl -L "$icon_download_url" -o "$ICON_PATH" -f; then
            echo "✅ Icon downloaded successfully!"
            break
        else
            echo "❌ Failed to download icon from: $icon_download_url"
            echo "Available icons: cursor-icon.png, cursor-black-icon.png"
            echo "Do you want to try another filename? (y/n)"
            read -r retry_icon
            if [[ ! "$retry_icon" =~ ^[Yy]$ ]]; then
                print_error "Installation cancelled due to icon download failure."
                exit 1
            fi
        fi
    done

    echo "🖥️ Creating .desktop entry for Cursor..."
    sudo tee "$DESKTOP_ENTRY_PATH" >/dev/null <<EOL
[Desktop Entry]
Name=Cursor AI IDE
Exec=${EXECUTABLE_PATH} --no-sandbox
Icon=${ICON_PATH}
Type=Application
Categories=Development;
EOL

    # Set standard permissions for .desktop file (644 = rw-r--r--)
    echo "🔧 Setting desktop entry permissions..."
    sudo chmod 644 "$DESKTOP_ENTRY_PATH"
    if [ $? -ne 0 ]; then
        print_error "Failed to set desktop entry permissions."
        exit 1
    fi
    echo "✅ Desktop entry created with proper permissions."

    print_success "Cursor AI IDE installation complete!"
}

# --- Update Function ---
updateCursor() {
    if [ ! -d "$CURSOR_EXTRACT_DIR" ]; then
        print_error "Cursor is not installed. Please run the installer first."
        exec "$0"
    fi

    figlet -f slant "Update Cursor"
    echo "🆙 Updating Cursor AI IDE..."

    install_dependencies

    local cursor_download_path=$(get_appimage_path "update")

    process_appimage "$cursor_download_path" "update"

    print_success "Cursor AI IDE update complete!"
}

# --- Restore Icons Function ---
restoreIcons() {
    if [ ! -d "$CURSOR_EXTRACT_DIR" ]; then
        print_error "Cursor is not installed. Please run the installer first."
        exec "$0"
    fi

    figlet -f slant "Restore Icons"
    echo "🎨 Restoring Cursor AI IDE icons..."

    echo "Available icons:"
    echo "1. cursor-icon.png - Standard Cursor logo with blue background"
    echo "2. cursor-black-icon.png - Cursor logo with dark/black background"
    echo "------------------------"
    read -rp "Enter icon filename (e.g., cursor-icon.png, cursor-black-icon.png): " icon_name_from_github

    if [ -z "$icon_name_from_github" ]; then
        print_error "No icon filename provided. Exiting."
        exit 1
    fi

    local icon_download_url="https://raw.githubusercontent.com/hieutt192/Cursor-ubuntu/Cursor-ubuntu24.04/images/$icon_name_from_github"
    echo "🎨 Downloading icon to $ICON_PATH..."

    # Download the new icon
    if sudo curl -L "$icon_download_url" -o "$ICON_PATH" -f; then
        echo "✅ Icon downloaded successfully!"

        # Update the desktop entry with the new icon
        echo "🖥️ Updating desktop entry with new icon..."
        sudo tee "$DESKTOP_ENTRY_PATH" >/dev/null <<EOL
[Desktop Entry]
Name=Cursor AI IDE
Exec=${EXECUTABLE_PATH} --no-sandbox
Icon=${ICON_PATH}
Type=Application
Categories=Development;
EOL

        # Set proper permissions for .desktop file
        sudo chmod 644 "$DESKTOP_ENTRY_PATH"
        if [ $? -eq 0 ]; then
            echo "✅ Desktop entry updated with proper permissions."
            print_success "Icon restoration complete!"
        else
            print_error "Failed to set desktop entry permissions."
            exit 1
        fi
    else
        print_error "Failed to download the icon. Please check the filename and try again."
        exit 1
    fi
}

# --- Uninstall Function ---
uninstallCursor() {
    figlet -f slant "Uninstall Cursor"
    echo "🗑️ Uninstalling Cursor AI IDE from Ubuntu..."
    
    # Check if Cursor is installed
    if [ ! -d "$CURSOR_EXTRACT_DIR" ] && [ ! -f "$DESKTOP_ENTRY_PATH" ]; then
        print_info "Cursor AI IDE does not appear to be installed on this system."
        echo "No files found at:"
        echo "  - $CURSOR_EXTRACT_DIR"
        echo "  - $DESKTOP_ENTRY_PATH"
        return 0
    fi
    
    # Confirm uninstallation
    echo "⚠️ This will completely remove Cursor AI IDE from your system."
    echo "Files to be removed:"
    
    if [ -d "$CURSOR_EXTRACT_DIR" ]; then
        echo "  📁 Installation directory: $CURSOR_EXTRACT_DIR"
    fi
    
    if [ -f "$DESKTOP_ENTRY_PATH" ]; then
        echo "  🖥️ Desktop entry: $DESKTOP_ENTRY_PATH"
    fi
    
    echo ""
    echo "⚠️ Note: Your Cursor settings and projects will NOT be affected."
    echo ""
    read -rp "Are you sure you want to uninstall Cursor? (y/N): " confirm_uninstall
    
    if [[ ! "$confirm_uninstall" =~ ^[Yy]$ ]]; then
        print_info "Uninstallation cancelled."
        return 0
    fi
    
    echo "🗑️ Removing Cursor AI IDE..."
    
    # Remove installation directory
    if [ -d "$CURSOR_EXTRACT_DIR" ]; then
        echo "📁 Removing installation directory..."
        sudo rm -rf "$CURSOR_EXTRACT_DIR"
        if [ $? -eq 0 ]; then
            echo "✅ Installation directory removed successfully."
        else
            print_error "Failed to remove installation directory. Please check permissions."
            return 1
        fi
    fi
    
    # Remove desktop entry
    if [ -f "$DESKTOP_ENTRY_PATH" ]; then
        echo "🖥️ Removing desktop entry..."
        sudo rm -f "$DESKTOP_ENTRY_PATH"
        if [ $? -eq 0 ]; then
            echo "✅ Desktop entry removed successfully."
        else
            print_error "Failed to remove desktop entry. Please check permissions."
            return 1
        fi
    fi
    
    echo "🗑️ Updating desktop entries..."
    echo "💡 To refresh your application menu, you may need to:"
    echo "   • Log out and log back in"
    echo "   • Restart your computer"
    echo "   • Or wait a few minutes for automatic refresh"
    
    print_success "Cursor AI IDE has been successfully uninstalled from your system."
    echo ""
    echo "📝 Important Notes:"
    echo "   • Your Cursor settings and projects are preserved"
    echo "   • To reinstall: run this script again and choose option 1"
    echo "   • If old icons persist after reinstall:"
    echo "     - Log out and log back in"
    echo "     - Restart your computer for complete refresh"
}

# --- Main Menu ---
install_dependencies

figlet -f slant "Cursor AI IDE"
echo "For Ubuntu 24.04"
echo "-------------------------------------------------"
echo "  /\\_/\\"
echo " ( o.o )"
echo "  > ^ <"
echo "------------------------"
echo "1. 💿 Install Cursor"
echo "2. 🆙 Update Cursor"
echo "3. 🎨 Restore Icons"
echo "4. 🗑️  Uninstall Cursor"
echo "Note: If the menu reappears after choosing an option, check any error message above."
echo "------------------------"

read -rp "Please choose an option (1, 2, 3, or 4): " choice

case $choice in
    1)
        installCursor
        ;;
    2)
        updateCursor
        ;;
    3)
        restoreIcons
        ;;
    4)
        uninstallCursor
        ;;
    *)
        print_error "Invalid option. Please choose 1, 2, 3, or 4."
        exit 1
        ;;
esac

exit 0
