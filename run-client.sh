ansible-playbook ec2-stack-client.yml \
    -i inventory/prod/hosts \
    --vault-password-file password \
    --extra-vars=@extra-vars-client.yml

