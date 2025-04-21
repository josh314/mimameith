ansible-playbook playbooks/ec2-stack.yml \
    -i inventory/prod/hosts \
    --vault-password-file password \
    --extra-vars=@extra-vars.yml

