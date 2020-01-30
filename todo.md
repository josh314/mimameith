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
  - [ ] database
    - [ ] elastic IP?
    - [ ] security group
    - [ ] replica provisioning
  - [ ] removable block storage
    - [ ] attach/detach to instances
    - [ ] XFS file system to support mongodb's WiredTiger storage engine
  

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

- [*] restart machine (required by updates)

- [ ] inventory
  - [ ] production
    - [ ] group_vars
  - [*] add db_servers to inventory
  - [ ] dynamic inventory
    - not needed for the deploy-from-scratch scripts but would be for update scripts

- [ ] mongodb
  - [ ] SSL/TLS support
  - [ ] XFS file system preferred for mongodb
  - [*] backup playbook/role
    - [*] mongodump
    - [*] tar dump
    - [*] save to S3
    - [ ] (optional) purge old backups
    - [*] cron (either create a cron on a host machine or run playbook as a cron on the control machine)
  - [ ] install-mongo role
    - [*] ensure DB directory
    - [ ] linux user associated with mongo
    - [ ] mongod.conf template
      - [*] bind_ip for remote connections
      - [*] enable authentication
    - [*] mongodb user(s)
      - [*] admin
      - [*] lot commander
    - [*] start daemon as service
    - [ ] sharding and replication?
    - [ ] encryption
  - [ ] application-specifc setup (role, playbook or just a set of tasks?)
      - [ ] create db & collections
      - [ ] create indices
      - [*] backfill read from backup
- [ ] distinct secrets.yml files for each environment/cluster

- [ ] python virtual environment role
  - [ ] ensurepip not installed with bionic's python3 (suggested to `apt-get install python3-venv`)


# Bugs/Warnings
- [ ] creating the admin user on mongo instances fails on the second time through since the first time uses local exception
  - This can be circumvented with `ignore_errors` but something cleaner would be nice (some conditional for use with `when`)
- [ ] intermittent mongorestore error on ec2 instance
  - return code -9
  - got explicit out of memeory error before but usually nothing in particular is visible in verbose output
    - using a single worker and only doing one collection at a time in order to minimize load
  - may have been caused by trying to restore the admin db. excluding that now.