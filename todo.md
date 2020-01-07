- [ ] lot commander role
  - [*] AWS credentials on remote (S3 access)
  - [*] git repo branch
  - [*] don't hardcode in the Shopify store
  - [ ] app config file
    - [*] ability to toggle skipAuth
    - [ ] environment
  - [ ] Typescript refactor
    - [ ] config file
    - [ ] build command
  - [ ] use private/public IP for database depending on environment
  - [*] session secret envvar

- [ ] ec2 provisioning
  - [ ] bionic AMI
  - [ ] security groups
  - [ ] DNS
  - [ ] monitoring (cloudwatch)

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

- [ ] restart machine (required by updates)

- [ ] load balancer
  - [*] nginx, obvs
    - [*] config task
  - [ ] certbot