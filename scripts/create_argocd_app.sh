#!/bin/bash

# Script to create an ArgoCD application (project) with specified parameters
# This script uses the ArgoCD CLI to create and deploy an application

# Configuration
REPO_URL="https://github.com/edtroleis/backstage-python-app.git"
PROJECT_NAME="default"
APP_NAME="python-app"
REVISION="main"
PATH="charts/python-app"
NAMESPACE="python"
ARGOCD_SERVER="argocd.test.com"
ARGOCD_USERNAME="admin"
ARGOCD_PASSWORD="edtroleis"  # Default password from your setup
DEST_SERVER="https://kubernetes.default.svc"
SYNC_POLICY="automated"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Function to login to ArgoCD
login_to_argocd() {
    print_status $BLUE "🔐 Logging into ArgoCD..."
    
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

# Function to check if repository exists in ArgoCD
check_repository() {
    print_status $BLUE "🔍 Checking if repository is available in ArgoCD..."
    
    if ! argocd repo list | grep -q "$REPO_URL"; then
        print_status $YELLOW "⚠️  Repository $REPO_URL not found in ArgoCD"
        print_status $BLUE "Adding repository to ArgoCD..."
        
        if argocd repo add $REPO_URL; then
            print_status $GREEN "✅ Repository added successfully!"
        else
            print_status $RED "❌ Failed to add repository"
            print_status $YELLOW "Please run the add_argocd_repo.sh script first or add the repository manually"
            exit 1
        fi
    else
        print_status $GREEN "✅ Repository is available in ArgoCD"
    fi
}

# Function to create namespace if it doesn't exist
create_namespace() {
    print_status $BLUE "📦 Checking if namespace '$NAMESPACE' exists..."
    
    if ! kubectl get namespace $NAMESPACE > /dev/null 2>&1; then
        print_status $BLUE "Creating namespace '$NAMESPACE'..."
        if kubectl create namespace $NAMESPACE; then
            print_status $GREEN "✅ Namespace '$NAMESPACE' created successfully!"
        else
            print_status $RED "❌ Failed to create namespace '$NAMESPACE'"
            exit 1
        fi
    else
        print_status $GREEN "✅ Namespace '$NAMESPACE' already exists"
    fi
}

# Function to check if application already exists
check_existing_app() {
    print_status $BLUE "🔍 Checking if application '$APP_NAME' already exists..."
    
    if argocd app list | grep -q "$APP_NAME"; then
        print_status $YELLOW "⚠️  Application '$APP_NAME' already exists in ArgoCD"
        
        # Get the existing application details
        print_status $BLUE "📋 Current application details:"
        argocd app get $APP_NAME --output wide || true
        
        read -p "Do you want to update the existing application? (y/n): " update_choice
        if [ "$update_choice" = "y" ] || [ "$update_choice" = "Y" ]; then
            return 1  # Indicate we should update
        else
            print_status $GREEN "✅ Application already configured. Exiting."
            exit 0
        fi
    fi
    
    return 0  # Application doesn't exist, proceed with creating
}

# Function to create ArgoCD application
create_application() {
    print_status $BLUE "🚀 Creating ArgoCD application '$APP_NAME'..."
    
    # Create the application with all specified parameters
    if argocd app create $APP_NAME \
        --repo $REPO_URL \
        --path $PATH \
        --dest-server $DEST_SERVER \
        --dest-namespace $NAMESPACE \
        --revision $REVISION \
        --project $PROJECT_NAME \
        --sync-policy $SYNC_POLICY \
        --auto-prune \
        --self-heal; then
        print_status $GREEN "✅ Application '$APP_NAME' created successfully!"
    else
        print_status $RED "❌ Failed to create application '$APP_NAME'"
        exit 1
    fi
}

# Function to update existing application
update_application() {
    print_status $BLUE "🔄 Updating existing application '$APP_NAME'..."
    
    # Update the application parameters
    if argocd app set $APP_NAME \
        --repo $REPO_URL \
        --path $PATH \
        --revision $REVISION \
        --dest-namespace $NAMESPACE \
        --sync-policy $SYNC_POLICY; then
        print_status $GREEN "✅ Application '$APP_NAME' updated successfully!"
    else
        print_status $RED "❌ Failed to update application '$APP_NAME'"
        exit 1
    fi
}

# Function to sync application
sync_application() {
    print_status $BLUE "🔄 Syncing application '$APP_NAME'..."
    
    if argocd app sync $APP_NAME; then
        print_status $GREEN "✅ Application '$APP_NAME' synced successfully!"
    else
        print_status $YELLOW "⚠️  Sync may have issues. Check the application status."
    fi
}

# Function to show application status
show_application_status() {
    print_status $BLUE "📊 Application Status:"
    print_status $BLUE "====================="
    
    # Show application details
    argocd app get $APP_NAME --output wide
    
    echo ""
    print_status $BLUE "📋 Application List:"
    argocd app list
    
    echo ""
    print_status $BLUE "🔗 Application URL:"
    print_status $GREEN "ArgoCD UI: https://$ARGOCD_SERVER/applications/$APP_NAME"
}

# Function to show usage instructions
show_usage() {
    echo "ArgoCD Application Creation Script"
    echo "================================="
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "This script creates an ArgoCD application with the following configuration:"
    echo ""
    echo "Configuration:"
    echo "  Repository URL: $REPO_URL"
    echo "  Application Name: $APP_NAME"
    echo "  Project Name: $PROJECT_NAME"
    echo "  Revision: $REVISION"
    echo "  Path: $PATH"
    echo "  Namespace: $NAMESPACE"
    echo "  Destination Server: $DEST_SERVER"
    echo "  Sync Policy: $SYNC_POLICY (with auto-prune and self-heal)"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --status       Show application status"
    echo "  --sync         Sync the application"
    echo "  --delete       Delete the application"
    echo "  --recreate     Delete and recreate the application"
    echo ""
    echo "Requirements:"
    echo "- ArgoCD server running and accessible"
    echo "- Valid ArgoCD credentials"
    echo "- kubectl access to create namespace"
    echo "- Repository available in ArgoCD"
    echo ""
    echo "The application will:"
    echo "- Auto-create the namespace if it doesn't exist"
    echo "- Deploy using Helm chart from $PATH"
    echo "- Enable automated sync with self-heal and prune"
}

# Function to delete application
delete_application() {
    print_status $YELLOW "⚠️  Deleting application '$APP_NAME'..."
    
    if argocd app list | grep -q "$APP_NAME"; then
        read -p "Are you sure you want to delete application '$APP_NAME'? (y/n): " confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            if argocd app delete $APP_NAME --cascade; then
                print_status $GREEN "✅ Application '$APP_NAME' deleted successfully!"
            else
                print_status $RED "❌ Failed to delete application '$APP_NAME'"
                exit 1
            fi
        else
            print_status $BLUE "Operation cancelled."
        fi
    else
        print_status $YELLOW "Application '$APP_NAME' not found in ArgoCD"
    fi
}

# Function to recreate application
recreate_application() {
    print_status $BLUE "🔄 Recreating application '$APP_NAME'..."
    
    # Delete if exists
    if argocd app list | grep -q "$APP_NAME"; then
        print_status $BLUE "Deleting existing application..."
        argocd app delete $APP_NAME --cascade
        
        # Wait a moment for deletion to complete
        sleep 5
    fi
    
    # Create new application
    create_application
    sync_application
}

# Main function
main() {
    print_status $PURPLE "🚀 Starting ArgoCD application creation..."
    print_status $BLUE ""
    print_status $BLUE "Configuration:"
    print_status $BLUE "  Repository: $REPO_URL"
    print_status $BLUE "  Application: $APP_NAME"
    print_status $BLUE "  Path: $PATH"
    print_status $BLUE "  Namespace: $NAMESPACE"
    print_status $BLUE "  Revision: $REVISION"
    print_status $BLUE ""
    
    # Login to ArgoCD
    login_to_argocd
    
    # Check if repository is available
    check_repository
    
    # Create namespace if needed
    create_namespace
    
    # Check if application already exists
    if check_existing_app; then
        # Create new application
        create_application
        sync_application
    else
        # Update existing application
        update_application
        sync_application
    fi
    
    # Show application status
    show_application_status
    
    print_status $GREEN ""
    print_status $GREEN "🎉 Application setup completed successfully!"
    print_status $BLUE ""
    print_status $BLUE "Next steps:"
    print_status $BLUE "1. Monitor deployment: argocd app wait $APP_NAME"
    print_status $BLUE "2. Check application logs: kubectl logs -n $NAMESPACE -l app=$APP_NAME"
    print_status $BLUE "3. Access ArgoCD UI: https://$ARGOCD_SERVER/applications/$APP_NAME"
    print_status $BLUE "4. Check application status: ./$(basename "$0") --status"
}

# Parse command line arguments
case "$1" in
    -h|--help)
        show_usage
        exit 0
        ;;
    --status)
        check_argocd_cli
        login_to_argocd
        show_application_status
        exit 0
        ;;
    --sync)
        check_argocd_cli
        login_to_argocd
        sync_application
        exit 0
        ;;
    --delete)
        check_argocd_cli
        login_to_argocd
        delete_application
        exit 0
        ;;
    --recreate)
        check_argocd_cli
        login_to_argocd
        check_repository
        create_namespace
        recreate_application
        show_application_status
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
