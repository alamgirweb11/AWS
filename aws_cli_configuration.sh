#!/bin/bash

# AWS CLI Installation and Configuration Script for Ubuntu
# Author: Almagir Hosen
# Description: Installs AWS CLI v2 and configures it with user credentials.

set -e  # Exit on any error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install AWS CLI v2
install_aws_cli() {
    print_status "Starting AWS CLI v2 installation..."
    
    # Update package list
    print_status "Updating package list..."
    sudo apt update -y
    
    # Install required dependencies
    print_status "Installing dependencies..."
    sudo apt install -y curl unzip
    
    # Check if AWS CLI is already installed
    if command_exists aws; then
        current_version=$(aws --version 2>&1 | cut -d/ -f2 | cut -d' ' -f1)
        print_warning "AWS CLI is already installed (version: $current_version)"
        read -p "Do you want to reinstall/update? (y/N): " reinstall
        if [[ ! $reinstall =~ ^[Yy]$ ]]; then
            print_status "Skipping AWS CLI installation..."
            return 0
        fi
    fi
    
    # Download AWS CLI v2
    print_status "Downloading AWS CLI v2..."
    # cd /tmp # Uncomment if you want to change directory
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    
    # Extract the installer
    print_status "Extracting AWS CLI installer..."
    unzip -q awscliv2.zip
    
    # Install AWS CLI
    print_status "Installing AWS CLI v2..."
    sudo ./aws/install --update
    
    # Verify installation
    if command_exists aws; then
        version=$(aws --version 2>&1)
        print_success "AWS CLI installed successfully: $version"
    else
        print_error "AWS CLI installation failed!"
        exit 1
    fi
    
    # Cleanup
    # rm -rf /tmp/aws /tmp/awscliv2.zip # Uncomment if you want to clean up the temporary files
    rm -rf ./aws ./awscliv2.zip

}

# Function to configure AWS CLI
configure_aws_cli() {
    print_status "Configuring AWS CLI..."
    
    # Check if AWS is already configured
    if aws sts get-caller-identity >/dev/null 2>&1; then
        print_warning "AWS CLI is already configured"
        current_user=$(aws sts get-caller-identity --query 'Arn' --output text 2>/dev/null || echo "Unknown")
        print_status "Current AWS identity: $current_user"
        read -p "Do you want to reconfigure? (y/N): " reconfigure
        if [[ ! $reconfigure =~ ^[Yy]$ ]]; then
            return 0
        fi
    fi
    
    echo
    print_status "Please enter your AWS credentials:"
    read -p "AWS Access Key ID: " access_key
    read -s -p "AWS Secret Access Key: " secret_key
    echo
    read -p "Default region name [us-east-1]: " region
    region=${region:-us-east-1}
    read -p "Default output format [json]: " output_format
    output_format=${output_format:-json}
    
    # Configure AWS CLI
    aws configure set aws_access_key_id "$access_key"
    aws configure set aws_secret_access_key "$secret_key"
    aws configure set default.region "$region"
    aws configure set default.output "$output_format"
    
    # Verify configuration
    if aws sts get-caller-identity >/dev/null 2>&1; then
        user_info=$(aws sts get-caller-identity --query 'Arn' --output text)
        print_success "AWS CLI configured successfully"
        print_status "Configured as: $user_info"
    else
        print_error "AWS CLI configuration failed!"
        exit 1
    fi
}

# Main execution
main() {
    print_status "AWS CLI Setup Script Starting..."
    echo "This script will:"
    echo "1. Install AWS CLI v2"
    echo "2. Configure AWS credentials"
    echo
    
    read -p "Continue? (Y/n): " continue_setup
    if [[ $continue_setup =~ ^[Nn]$ ]]; then
        print_status "Setup cancelled by user."
        exit 0
    fi
    
    # Install AWS CLI
    install_aws_cli
    
    # Configure AWS CLI
    configure_aws_cli
    
    print_success "Setup completed successfully!"
}

# Check if jq is installed (needed for JSON parsing)
if ! command_exists jq; then
    print_status "Installing jq for JSON parsing..."
    sudo apt update && sudo apt install -y jq
fi

# Run main function
main "$@"