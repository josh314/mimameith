ansible-playbook ec2-stack-client.yml \
    -i inventory/dev/hosts \
    --vault-password-file password \
    --verbose \
    --extra-vars=@extra-vars-client.yml
