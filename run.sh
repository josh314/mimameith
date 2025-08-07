#!/bin/bash

# Initialize variables
env=""
vendor=""

# Function to display usage

# Function to display usage
usage() {
    echo "Usage: $0 [--dev | --prod] [--vendor <vendor_name>]"
    exit 1
}

# Function to check if a vendor is valid
is_valid_vendor() {
    local vendor_name="$1"
    if grep -Fxq "$vendor_name" vendors.txt; then
        return 0
    else
        return 1
    fi
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
                vendor)
                    vendor="${!OPTIND}"
                    if [[ -z "$vendor" || "$vendor" == -* ]]; then
                        echo "Error: --vendor requires a value"
                        usage
                    fi
                    if [ ! -f "vendors.txt" ]; then
                        echo "Error: vendors.txt not found."
                        exit 1
                    fi
                    if ! is_valid_vendor "$vendor"; then
                        echo "Error: Invalid vendor. vendor must be one of:"
                        cat vendors.txt
                        echo
                        exit 1
                    fi
                    OPTIND=$((OPTIND + 1))
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

# Display the vendor name if provided
if [[ -n "$vendor" ]]; then
    echo "vendor: $vendor"
fi

# Display the vendor flag status
if [[ -n "$vendor" ]]; then
    playbook_file="playbooks/ec2-stack-vendor.yml"
    extra_vars_location="extra-vars-vendor.yml"
    extra_args="--extra-vars=vendor_handle=${vendor} ${verbosity}"
else
    playbook_file="playbooks/ec2-stack.yml"
    extra_vars_location="extra-vars.yml"
fi

# Set verbosity flag based on environment
[[ "$env" == "dev" ]] && verbose_flag="--verbose"

inventory_location="inventory/$env/hosts"

# Invoke ansible-playbook
ansible-playbook \
    -i "$inventory_location" \
    --vault-password-file password \
    --extra-vars="@${extra_vars_location}" \
    ${extra_args} \
    ${verbose_flag} \
    "$playbook_file"