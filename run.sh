#!/bin/bash

# Initialize variables
env=""
client=""

# Function to display usage

# Function to display usage
usage() {
    echo "Usage: $0 [--dev | --prod] [--client <client_name>]"
    exit 1
}

# Function to check if a client is valid
is_valid_client() {
    local client_name="$1"
    if grep -Fxq "$client_name" clients.txt; then
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
                client)
                    client="${!OPTIND}"
                    if [[ -z "$client" || "$client" == -* ]]; then
                        echo "Error: --client requires a value"
                        usage
                    fi
                    if [ ! -f "clients.txt" ]; then
                        echo "Error: clients.txt not found."
                        exit 1
                    fi
                    if ! is_valid_client "$client"; then
                        echo "Error: Invalid client. Client must be one of:"
                        cat clients.txt
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

# Display the client name if provided
if [[ -n "$client" ]]; then
    echo "Client: $client"
fi

# Display the client flag status
if [[ -n "$client" ]]; then
    playbook_file="ec2-stack-client.yml"
    extra_vars_location="extra-vars-client.yml"
    extra_args="--extra-vars=client_handle=${client}"
else
    playbook_file="ec2-stack.yml"
    extra_vars_location="extra-vars.yml"
fi

inventory_location="inventory/$env/hosts"

# Invoke ansible-playbook
ansible-playbook \
    -i "$inventory_location" \
    --vault-password-file password \
    --extra-vars="@${extra_vars_location}" \
    ${extra_args} \
    "$playbook_file"