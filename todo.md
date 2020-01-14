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
  - [ ] AMI
  - [ ] instance type
  - [ ] security groups
  - [ ] DNS
  - [*] elastic IP for load balancer
  - [ ] monitoring (cloudwatch)
  - [ ] wait longer before moving on to instance playbooks
    - [ ] update packages task (apt) fails when instance has just been provisioned
    

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
  - [ ] proxy to 443 on app servers
  - [ ] certbot

- [ ] app servers
  - [ ] self-signed certs
  - [ ] setup nginx for certs