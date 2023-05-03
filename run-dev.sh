ansible-playbook ec2-stack.yml \
    -i inventory/dev/hosts \
    --vault-password-file password \
    --verbose \
    --extra-vars=@extra-vars.yml

