#!/bin/bash

# Initialize variables
env=""
check_mode=false

# Function to display usage

# Function to display usage
usage() {
    echo "Usage: $0 [--dev | --prod][--check]"
    exit 1
}

# Parse command line arguments using getopts
while getopts ":dp-:" opt; do
    case $opt in
        -)
            case "${OPTARG}" in
                dev)
                    env="dev"
                    ;;
                prod)
                    env="prod"
                    ;;
                check)
                    check_mode=true
                    ;;
                *)
                    usage
                    ;;
            esac
            ;;
        d)
            env="dev"
            ;;
        p)
            env="prod"
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# If no valid environment argument is provided, prompt the user for input
if [[ -z "$env" ]]; then
    # Set a default value
    default_env="dev"

    # Prompt the user for input with a default value
    echo "Which environment to deploy to? (prod/[dev])"
    read -p "  Enter a value: " env

    # If the user doesn't enter anything, use the default value
    env=${env:-$default_env}

    # Check if the input is either 'dev' or 'prod'
    if [[ "$env" != "dev" && "$env" != "prod" ]]; then
        echo "Error: Invalid environment. Please enter 'dev' or 'prod'."
        exit 1
    fi
fi

# Display the selected environment
echo "Environment set to: $env"

# Set verbosity flag based on environment
[[ "$env" == "dev" ]] && verbose_flag="--verbose"

# Set check mode flag if specified
check_flag=""
$check_mode && check_flag="--check"
echo "Check mode: $check_mode"

inventory_location="inventory/$env/hosts"
echo "Using inventory file: $inventory_location"

# Invoke ansible-playbook
ansible-playbook \
    -i "$inventory_location" \
    --vault-password-file password \
    --extra-vars="@extra-vars.yml" \
    ${verbose_flag} \
    ${check_flag} \
    playbooks/db-ec2.yml