- [ ] lot commander role
  - [*] AWS credentials on remote (S3 access)
  - [ ] git repo branch
  - [ ] don't hardcode in the Shopify store
  - [ ] app config file
    - [*] ability to toggle skipAuth
    - [ ] environment
  - [ ] Typescript refactor
    - [ ] config file
    - [ ] build command
  - [ ] use private/public IP for database depending on environment

- [ ] ec2 provisioning
  - [ ] security groups
  - [ ] DNS

- [ ] SSL/TLS
  - [ ] certbot
  - [ ] self-signed for development pruposes

- [ ] tighten file permissions
  - [ ] .aws folder
  - [ ] config file (holds many secrets)
  - [ ] compare the ansible_user with the user responsible for running lot-commander

- [ ] test behavior on reboot
  - [ ] nginx
  - [ ] pm2 lot-commander
