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
    - [*] import from var file
  - [ ] instance type
    - [*] import from var file
  - [ ] security groups
    - [ ] create in ansible or at least check existence
    - [ ] choose based on env and org
  - [ ] DNS
  - [*] elastic IP for load balancer
  - [ ] monitoring (cloudwatch)
  - [*] version tag on app server instances
  - [ ] instance names
    - [ ] number them: 'app_server_1', etc
    

- [ ] SSL/TLS
  - [ ] load balancer
    - [*] openssl key pair
    - [ ] certificate
      - [*] let's encrypt using DNS challenge
      - [*] self-signed
      - [*] switch between let's encrypt and self-signed based on environment
      - [ ] full chain (Firefox says cert is incomplete)
  - [ ] app servers (may be unnecessary if we trust AWS intranet sufficiently)
    - [ ] openssl key pair
    - [ ] self-signed cert
    - [ ] change `tls_enabled` to `true` in `app.yml`
    - [ ] modify load balancer nginx config to proxy with HTTPS to the app server (port 443)

- [ ] tighten file permissions
  - [ ] .aws folder
  - [ ] config file (holds many secrets)
  - [ ] compare the ansible_user with the user responsible for running lot-commander

- [ ] test behavior on reboot
  - [ ] nginx
  - [ ] pm2 lot-commander

- [ ] restart machine (required by updates)

- [ ] inventory
  - [ ] production
    - [ ] group_vars
  - [ ] hanes?

- [ ] mongodb
  - [ ] backup playbook
    - [ ] S3 bucket?
    - [ ] purge old backups
  - [ ] deploy playbook
    - [ ] linux user associated with mongo
    - [ ] mongodb user(s)
      - [ ] admin
      - [ ] lot commander 
    - [ ] backfill read from backup

- [ ] distinct secrets.yml files for each environment/cluster

# Bugs
- [*] load balancer not forwarding HTTP requests to HTTPS