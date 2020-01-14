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
    - [ ] import from var file
  - [ ] security groups
  - [ ] DNS
  - [*] elastic IP for load balancer
  - [ ] monitoring (cloudwatch)
  - [ ] wait longer before moving on to instance playbooks
    - [ ] update packages task (apt) fails when instance has just been provisioned
    

- [ ] SSL/TLS
  - [ ] load balancer
    - [*] openssl key pair
    - [ ] certificate
      - [ ] certbot
      - [*] self-signed
      - [ ] switch between certbot and self-signed based on environment
  - [ ] app servers (may be unnecessary if we trust AWS intranet sufficiently)
    - [ ] openssl key pair
    - [ ] self-signed cert
    - [ ] change `tls_enabled` to `true` in `app.yml`
    - [ ] modify load balancer nginx config to proxy with HTTPS to the app server (port 443)

- [ ] nginx
  - [ ] variable and settings for whether to proxy to HTTPS in roundrobin server group

- [ ] tighten file permissions
  - [ ] .aws folder
  - [ ] config file (holds many secrets)
  - [ ] compare the ansible_user with the user responsible for running lot-commander

- [ ] test behavior on reboot
  - [ ] nginx
  - [ ] pm2 lot-commander

- [ ] restart machine (required by updates)
