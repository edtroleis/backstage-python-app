#!/bin/bash

# Script to check and update Windows hosts file for multiple local development domains
# This script works with WSL or Git Bash on Windows

# Define the entries to check/add
declare -A HOSTS_ENTRIES=(
    ["argocd.test.com"]="127.0.0.1"
    ["python-app.test.com"]="127.0.0.1"
)

# Windows hosts file location
WINDOWS_HOSTS="/mnt/c/Windows/System32/drivers/etc/hosts"
# Alternative path for Git Bash
GIT_BASH_HOSTS="/c/Windows/System32/drivers/etc/hosts"

# Function to detect the correct hosts file path
detect_hosts_file() {
    if [ -f "$WINDOWS_HOSTS" ]; then
        echo "$WINDOWS_HOSTS"
    elif [ -f "$GIT_BASH_HOSTS" ]; then
        echo "$GIT_BASH_HOSTS"
    else
        echo ""
    fi
}

# Function to check if entry exists in hosts file
check_hosts_entry() {
    local hosts_file="$1"
    local hostname="$2"
    if grep -q "$hostname" "$hosts_file" 2>/dev/null; then
        return 0  # Entry exists
    else
        return 1  # Entry doesn't exist
    fi
}

# Function to get current entry for hostname
get_current_entry() {
    local hosts_file="$1"
    local hostname="$2"
    grep "$hostname" "$hosts_file" 2>/dev/null | head -n1 | tr -s ' ' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//'
}

# Function to add entry to hosts file
add_hosts_entry() {
    local hosts_file="$1"
    local ip="$2"
    local hostname="$3"
    local entry="$ip    $hostname"
    
    echo "Adding entry: $entry"
    
    # Add entry
    echo "" >> "$hosts_file"
    echo "# Added by development setup script" >> "$hosts_file"
    echo "$entry" >> "$hosts_file"
    
    echo "✅ Entry added successfully!"
}

# Function to verify and update existing entry
update_hosts_entry() {
    local hosts_file="$1"
    local ip="$2"
    local hostname="$3"
    local expected_entry="$ip    $hostname"
    local current_entry=$(get_current_entry "$hosts_file" "$hostname")
    
    # Normalize entries for comparison (handle different spacing)
    local normalized_current=$(echo "$current_entry" | tr -s ' ' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//')
    local normalized_expected=$(echo "$expected_entry" | tr -s ' ' | sed 's/^[ \t]*//' | sed 's/[ \t]*$//')
    
    if [ "$normalized_current" = "$normalized_expected" ]; then
        echo "✅ Correct entry already exists: $current_entry"
        return 0
    else
        echo "⚠️  Different entry found: $current_entry"
        echo "Expected: $expected_entry"
        
        read -p "Do you want to update it? (y/n): " update_choice
        if [ "$update_choice" = "y" ] || [ "$update_choice" = "Y" ]; then
            # Replace the line
            sed -i "s/.*$hostname.*/$expected_entry/" "$hosts_file"
            echo "✅ Entry updated successfully!"
        else
            echo "Entry left unchanged."
        fi
    fi
}

# Function to create backup
create_backup() {
    local hosts_file="$1"
    local backup_file="${hosts_file}.backup.$(date +%Y%m%d_%H%M%S)"
    cp "$hosts_file" "$backup_file"
    echo "📋 Backup created: $backup_file"
}

# Function to process a single hosts entry
process_hosts_entry() {
    local hosts_file="$1"
    local hostname="$2"
    local ip="$3"
    
    echo ""
    echo "🔍 Checking entry for: $hostname"
    
    # Check if entry exists
    if check_hosts_entry "$hosts_file" "$hostname"; then
        echo "📋 Entry for $hostname found in hosts file"
        update_hosts_entry "$hosts_file" "$ip" "$hostname"
    else
        echo "📋 No entry found for $hostname"
        add_hosts_entry "$hosts_file" "$ip" "$hostname"
    fi
}

# Function to display current status
show_current_status() {
    local hosts_file="$1"
    
    echo ""
    echo "📝 Current hosts file entries for development domains:"
    echo "================================================="
    
    for hostname in "${!HOSTS_ENTRIES[@]}"; do
        local entry=$(grep "$hostname" "$hosts_file" 2>/dev/null || echo "❌ Not found")
        echo "$hostname: $entry"
    done
    
    echo "================================================="
}

# Main script execution
main() {
    echo "🔍 Checking Windows hosts file for development entries..."
    echo "Domains to check: ${!HOSTS_ENTRIES[*]}"
    
    # Detect hosts file location
    HOSTS_FILE=$(detect_hosts_file)
    
    if [ -z "$HOSTS_FILE" ]; then
        echo "❌ Error: Could not find Windows hosts file!"
        echo "Please run this script from WSL or Git Bash on Windows"
        echo ""
        echo "Expected locations:"
        echo "- WSL: $WINDOWS_HOSTS"
        echo "- Git Bash: $GIT_BASH_HOSTS"
        exit 1
    fi
    
    echo "📁 Using hosts file: $HOSTS_FILE"
    
    # Check if we have write permissions
    if [ ! -w "$HOSTS_FILE" ]; then
        echo "❌ Error: No write permission to hosts file!"
        echo "Please run this script as Administrator"
        echo ""
        echo "To run as Administrator:"
        echo "1. Open Command Prompt or PowerShell as Administrator"
        echo "2. Navigate to the script directory"
        echo "3. Run: bash $(basename "$0")"
        exit 1
    fi
    
    # Show current status before changes
    show_current_status "$HOSTS_FILE"
    
    # Create backup before making any changes
    local backup_needed=false
    for hostname in "${!HOSTS_ENTRIES[@]}"; do
        if ! check_hosts_entry "$HOSTS_FILE" "$hostname"; then
            backup_needed=true
            break
        fi
    done
    
    if [ "$backup_needed" = true ]; then
        create_backup "$HOSTS_FILE"
    fi
    
    # Process each hosts entry
    for hostname in "${!HOSTS_ENTRIES[@]}"; do
        local ip="${HOSTS_ENTRIES[$hostname]}"
        process_hosts_entry "$HOSTS_FILE" "$hostname" "$ip"
    done
    
    # Show final status
    show_current_status "$HOSTS_FILE"
    
    echo ""
    echo "🌐 You can now access:"
    for hostname in "${!HOSTS_ENTRIES[@]}"; do
        echo "   https://$hostname"
    done
    echo ""
    echo "🚀 Development environment is ready!"
}

# Check if running with help parameter
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Windows Hosts File Manager for Development"
    echo "=========================================="
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "This script checks and manages Windows hosts file entries for local development."
    echo ""
    echo "Managed domains:"
    for hostname in "${!HOSTS_ENTRIES[@]}"; do
        local ip="${HOSTS_ENTRIES[$hostname]}"
        echo "  $ip    $hostname"
    done
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Requirements:"
    echo "- Run from WSL or Git Bash on Windows"
    echo "- Administrator privileges (to modify hosts file)"
    echo ""
    echo "The script will:"
    echo "1. Locate the Windows hosts file"
    echo "2. Check for existing development domain entries"
    echo "3. Add or update entries as needed"
    echo "4. Create a backup before making changes"
    echo "5. Show current status before and after changes"
    echo ""
    echo "Safety features:"
    echo "- Creates timestamped backups"
    echo "- Validates permissions before modifications"
    echo "- Confirms changes with user when updating existing entries"
    exit 0
fi

# Check if running with status parameter
if [ "$1" = "--status" ] || [ "$1" = "-s" ]; then
    HOSTS_FILE=$(detect_hosts_file)
    if [ -z "$HOSTS_FILE" ]; then
        echo "❌ Error: Could not find Windows hosts file!"
        exit 1
    fi
    
    echo "📁 Hosts file: $HOSTS_FILE"
    show_current_status "$HOSTS_FILE"
    exit 0
fi

# Run main function
main
