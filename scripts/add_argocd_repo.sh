#!/bin/bash

# Script to add a public Git repository to ArgoCD
# This script uses the ArgoCD CLI to add a repository

# Configuration
REPO_URL="https://github.com/edtroleis/backstage-python-app.git"
REPO_NAME="default"
ARGOCD_SERVER="argocd.test.com"
ARGOCD_USERNAME="admin"
ARGOCD_PASSWORD="edtroleis"  # Default password from your setup

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to check if ArgoCD CLI is installed
check_argocd_cli() {
    if ! command -v argocd &> /dev/null; then
        print_status $RED "❌ ArgoCD CLI not found!"
        print_status $YELLOW "Installing ArgoCD CLI..."
        
        # Download and install ArgoCD CLI
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
        
        if command -v argocd &> /dev/null; then
            print_status $GREEN "✅ ArgoCD CLI installed successfully!"
        else
            print_status $RED "❌ Failed to install ArgoCD CLI"
            exit 1
        fi
    else
        print_status $GREEN "✅ ArgoCD CLI is already installed"
    fi
}

# Function to login to ArgoCD
login_to_argocd() {
    print_status $BLUE "🔐 Logging into ArgoCD..."
    
    # Check if ArgoCD server is accessible
    if ! curl -k -s --connect-timeout 10 https://$ARGOCD_SERVER > /dev/null; then
        print_status $RED "❌ Cannot reach ArgoCD server at https://$ARGOCD_SERVER"
        print_status $YELLOW "Please ensure:"
        print_status $YELLOW "  1. ArgoCD is running"
        print_status $YELLOW "  2. Ingress is properly configured"
        print_status $YELLOW "  3. Hosts file contains: 127.0.0.1 $ARGOCD_SERVER"
        exit 1
    fi
    
    # Attempt to login
    if argocd login $ARGOCD_SERVER --username $ARGOCD_USERNAME --password $ARGOCD_PASSWORD --insecure --grpc-web; then
        print_status $GREEN "✅ Successfully logged into ArgoCD"
    else
        print_status $RED "❌ Failed to login to ArgoCD"
        print_status $YELLOW "Please check:"
        print_status $YELLOW "  1. ArgoCD server URL: https://$ARGOCD_SERVER"
        print_status $YELLOW "  2. Username: $ARGOCD_USERNAME"
        print_status $YELLOW "  3. Password: $ARGOCD_PASSWORD"
        
        # Try to get current password from Kubernetes
        print_status $BLUE "🔍 Trying to get current admin password from Kubernetes..."
        if command -v kubectl &> /dev/null; then
            CURRENT_PWD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" 2>/dev/null | base64 -d 2>/dev/null)
            if [ ! -z "$CURRENT_PWD" ]; then
                print_status $YELLOW "Try using this password: $CURRENT_PWD"
                if argocd login $ARGOCD_SERVER --username $ARGOCD_USERNAME --password $CURRENT_PWD --insecure --grpc-web; then
                    print_status $GREEN "✅ Successfully logged into ArgoCD with retrieved password"
                    ARGOCD_PASSWORD=$CURRENT_PWD
                else
                    print_status $RED "❌ Login failed even with retrieved password"
                    exit 1
                fi
            else
                print_status $YELLOW "Could not retrieve password from Kubernetes"
                exit 1
            fi
        else
            print_status $YELLOW "kubectl not available to retrieve password"
            exit 1
        fi
    fi
}

# Function to check if repository already exists
check_existing_repo() {
    print_status $BLUE "🔍 Checking if repository already exists..."
    
    # List repositories and check if our repo exists
    if argocd repo list | grep -q "$REPO_URL"; then
        print_status $YELLOW "⚠️  Repository $REPO_URL already exists in ArgoCD"
        
        # Get the existing repository details
        print_status $BLUE "📋 Current repository details:"
        argocd repo list | grep "$REPO_URL" || true
        
        read -p "Do you want to update the existing repository? (y/n): " update_choice
        if [ "$update_choice" = "y" ] || [ "$update_choice" = "Y" ]; then
            return 1  # Indicate we should update
        else
            print_status $GREEN "✅ Repository already configured. Exiting."
            exit 0
        fi
    fi
    
    return 0  # Repository doesn't exist, proceed with adding
}

# Function to add repository to ArgoCD
add_repository() {
    print_status $BLUE "📦 Adding repository to ArgoCD..."
    
    # Add the repository
    if argocd repo add $REPO_URL --name $REPO_NAME; then
        print_status $GREEN "✅ Repository added successfully!"
    else
        print_status $RED "❌ Failed to add repository"
        exit 1
    fi
}

# Function to verify repository connection
verify_repository() {
    print_status $BLUE "🔗 Verifying repository connection..."
    
    # List repositories to confirm it was added
    print_status $BLUE "📋 Current repositories in ArgoCD:"
    argocd repo list
    
    # Check connection status
    if argocd repo get $REPO_URL > /dev/null 2>&1; then
        print_status $GREEN "✅ Repository connection verified!"
        
        # Show repository details
        print_status $BLUE "📋 Repository details:"
        argocd repo get $REPO_URL
    else
        print_status $YELLOW "⚠️  Repository added but connection verification failed"
        print_status $YELLOW "This might be normal and the connection will be established when first used"
    fi
}

# Function to show usage instructions
show_usage() {
    echo "ArgoCD Repository Management Script"
    echo "=================================="
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "This script adds a public Git repository to ArgoCD."
    echo ""
    echo "Configuration:"
    echo "  Repository URL: $REPO_URL"
    echo "  Repository Name: $REPO_NAME"
    echo "  ArgoCD Server: https://$ARGOCD_SERVER"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --list         List current repositories"
    echo "  --remove       Remove the repository"
    echo ""
    echo "Requirements:"
    echo "- ArgoCD server running and accessible"
    echo "- Valid ArgoCD credentials"
    echo "- Internet connection to access the Git repository"
    echo ""
    echo "After adding the repository, you can create applications using:"
    echo "  argocd app create <app-name> --repo $REPO_URL --path <path> --dest-server https://kubernetes.default.svc --dest-namespace <namespace>"
}

# Function to list repositories
list_repositories() {
    print_status $BLUE "📋 Current repositories in ArgoCD:"
    
    if ! argocd repo list; then
        print_status $RED "❌ Failed to list repositories. Please check your ArgoCD connection."
        exit 1
    fi
}

# Function to remove repository
remove_repository() {
    print_status $YELLOW "⚠️  Removing repository from ArgoCD..."
    
    if argocd repo list | grep -q "$REPO_URL"; then
        read -p "Are you sure you want to remove repository $REPO_URL? (y/n): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            if argocd repo rm $REPO_URL; then
                print_status $GREEN "✅ Repository removed successfully!"
            else
                print_status $RED "❌ Failed to remove repository"
                exit 1
            fi
        else
            print_status $BLUE "Operation cancelled."
        fi
    else
        print_status $YELLOW "Repository $REPO_URL not found in ArgoCD"
    fi
}

# Main function
main() {
    print_status $BLUE "🚀 Starting ArgoCD repository setup..."
    
    # Check and install ArgoCD CLI if needed
    check_argocd_cli
    
    # Login to ArgoCD
    login_to_argocd
    
    # Check if repository already exists
    if check_existing_repo; then
        # Add new repository
        add_repository
    else
        # Update existing repository (remove and re-add)
        print_status $BLUE "🔄 Updating existing repository..."
        argocd repo rm $REPO_URL
        add_repository
    fi
    
    # Verify the repository
    verify_repository
    
    print_status $GREEN "🎉 Repository setup completed successfully!"
    print_status $BLUE ""
    print_status $BLUE "Next steps:"
    print_status $BLUE "1. You can now create applications from this repository"
    print_status $BLUE "2. Use ArgoCD UI at https://$ARGOCD_SERVER to manage applications"
    print_status $BLUE "3. Or use CLI commands to create applications"
    print_status $BLUE ""
    print_status $BLUE "Example CLI command to create an application:"
    print_status $BLUE "argocd app create my-app \\"
    print_status $BLUE "  --repo $REPO_URL \\"
    print_status $BLUE "  --path k8s \\"
    print_status $BLUE "  --dest-server https://kubernetes.default.svc \\"
    print_status $BLUE "  --dest-namespace default"
}

# Parse command line arguments
case "$1" in
    -h|--help)
        show_usage
        exit 0
        ;;
    --list)
        check_argocd_cli
        login_to_argocd
        list_repositories
        exit 0
        ;;
    --remove)
        check_argocd_cli
        login_to_argocd
        remove_repository
        exit 0
        ;;
    "")
        # No arguments, run main function
        main
        ;;
    *)
        print_status $RED "❌ Unknown option: $1"
        show_usage
        exit 1
        ;;
esac
