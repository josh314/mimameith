# Mímameith

Infrastructure code for deploying Mímameith, the distributed application stack for internal Expresshop operations.

### Etymology

"Mimameith" is an anglicization of **Mímameiðr**, another name for the Norse world-tree, Yggdrasil. As per [Wikipedia](https://en.wikipedia.org/wiki/M%C3%ADmamei%C3%B0r):

> In Norse mythology, Mímameiðr (Old Norse "Mimi's tree") is a tree whose branches stretch over every land, is unharmed by fire or metal, bears fruit that assists pregnant women, and upon whose highest bough roosts the cock Víðópnir. Mímameiðr is solely attested in the Old Norse poem Fjölsvinnsmál. Due to parallels between descriptions of the two, scholars generally consieder Mímameiðr to be another name for the world tree Yggdrasil, along with the similarly named Hoddmímis holt, a wood within which Líf and Lífthrasir are foretold to take refuge during the events of Ragnarök. Mímameiðr is sometimes modernly anglicized as Mimameid or Mimameith.

However it is named, the world tree's roots and branches connect all the realms of Norse mythology, just as Mimameith connects the different aspects of our business.


## Ansible
See below for detailed playbook descriptions. Contains secret file(s) encrypted with `ansible-vault`.

### Secrets

The encrypted, password-protected files are managed by `ansible-vault`. You can view the file with

```
ansible-vault view secrets.yml
```

To modify `secrets.yml`, open the file with `ansible-vault` (this will use the host $EDITOR):

```
ansible-vault edit secrets.yml
```

Alternately, first decrypt:

```
ansible-vault decrypt secrets.yml
```

then make your edits in the text editor of your choice. When you are finished editting, re-encrypt:

```
ansible-vault encrypt secrets.yml
```

When decrypting/re-encrypting, you actually setting a new password at the second stage so you will have to input the password twice for confirmation. See the help for `ansible-vault` for more options.

#### Inline encryption

There may also be inline encrypted strings embedded in plain-text files. To generate an inline encrypted string, use the command

```
ansible-vault encrypt_string <your_string>
```

You will be asked for a passwword and then presented an output like

```
!vault | 
      $ANSIBLE_VAULT;1.1;AES256 613036316133613365356534303633373835343639663236653537326534633537663430313730636635303662333663646331323131616334323235386635640a393237383030613439353262333161323466363765646661326562383535323334613433333934373831323939323238663437623638633564393663386537340a38373865313265343862323139653530393931383637373862646530623232326232346363383163356365323431346337316262623132656531393965363630
```

Copy this all (including the `!vault |`) into a plaintext variable file (cannot be used directly in playbooks).

#### Password 

In order to use any of the playbooks which import an encrypted file (or file with inline encryption) a password must be input.

Usage:

```
ansible-playbook app.yml -i hosts.yml --ask-vault-password
```

or

```
ansible-playbook app.yml -i hosts.yml --vault-password-file /path/to/password.txt
```

If `/path/to/password.txt` has the executable-bit set, then Ansible will execute it and use the contents of `stdout` as the vault password.

#### Session cookie secret

To generate a new secret for session cookies, replace the `session_secret` field in `secrets.yml` with the result of

```
head -c20 /dev/urandom | base64
```

This should be done semi-regularly. Note that old sessions will not be valid on servers instantiated with the new secret.

### Playbooks

#### Database (db-only workflow)

`db-ec2.yml` provisions (or reconfigures) just the MongoDB tier: an EC2 instance, its Elastic IP/DNS, an IAM instance role scoped to the S3 backup/restore buckets (`mongo_s3_backup_s3_bucket`/`mongo_s3_restore_s3_bucket`), and then imports `mongo-server.yml` to install and configure MongoDB. This is the current, preferred way to stand up or update the db server — it replaces running the full `ec2-stack.yml` stack (see [Legacy](#legacy)) just to touch the database tier.

**Requires `ansible-roles` >= 6.2.0.** This workflow relies on IAM-role-based S3 access for backup/restore that was added in that version; older `ansible-roles` versions only support the static-credential path (`aws.credentials.admin.*`) that `ec2-stack.yml` still uses.

Run from the `ansible/` directory:

```
./deploy-db.sh --dev    # or --prod
./deploy-db.sh --prod --check   # dry run
```

This wraps `ansible-playbook -i inventory/<env>/hosts --vault-password-file password --extra-vars=@extra-vars.yml playbooks/db-ec2.yml` — see `extra-vars.sample.yml` for the variables it expects (e.g. `mongodb_major_version`, `db_server_eip`, `ubuntu_versions`).


#### `clone-mongo.yml`

Use shell commands `mongodump` and `mongorestore` to clone mongo installation from one host to another.

```
ansible-playbook clone-mongo.yml \
    -i 'localhost' \
    -e src_db_host=ec2-35-174-137-1.compute-1.amazonaws.com \
    -e src_db_user=**************** \
    -e src_db_password=**************** \
    -e dest_db_host='192.168.33.2' \
    -e dest_db_user=****************** \
    -e dest_db_password=****************** 
```

Other params with defaults are

```
src_db_port: '27017'
dest_db_port: '27017'
db: ehdb
```

#### `mongo-backup.yml`

Runs `mongo_tools` and `mongo_s3_backup` roles. Usage example:

```
ansible-playbook mongo-backup.yml \
    -i inventory/vagrant/hosts \
    --vault-password-file password \
    -e @secrets.yml \
    -e mongo_s3_backup_db_host=ec2-35-174-137-1.compute-1.amazonaws.com
```

In the example above, we are running ansible on a vagrant-provisioned control server while the db to be copied lives at `ec2-35-174-137-1.compute-1.amazonaws.com`. Without the `mongo_s3_backup_host` var, the playbook will try to copy from mongodb installation on the server the playbook is being run against.

#### `ec2-cronbox.yml`

A separate playbook to configure a server for occasional crons.

```
ansible-playbook ec2-cronbox.yml \
    -i inventory/prod/hosts \
    --vault-password-file password
```

### Vagrant

A `Vagrantfile` is included to spin up virtual machines for local use. It uses the same ansible playbooks from production for setting up the provisioned VMs (obviously without the ). A full development stack is available, including its various intranet connections.

There are also control machines which are not part of the stack but useful for performing maintenance tasks on other servers.

Inventory host and variable files are in `inventory/vagrant`.

## SSM Session Manager

For the app servers, we use AWS SSM Session Manager to connect to the instances instead of SSH. This allows us to avoid opening SSH ports on the servers and managing SSH keys. To start a session, use the command

```
aws ssm start-session --target <instance-id>
```

## Legacy

The material below documents the original EC2-based **lot-commander** stack: the app server, its Nginx load balancer, and the AMI pipeline that built the app server image. **lot-commander's app-server tier now runs on ECS, managed in a separate project outside this repo** — the app-server/load-balancer portions here are no longer the live deploy path. The database-tier portion of `ec2-stack.yml` has been superseded by the dedicated [Database (db-only workflow)](#database-db-only-workflow) documented above. Kept for historical reference, not deleted — see `CLAUDE.md` for more on the current state of this transition.

### `ec2-stack.yml`

Provisioned the full lot-commander stack — app server(s), load balancer, and db server — gated by `provision__*`/`configure__*` toggles in `extra-vars.yml`.

```
ansible-playbook ec2-stack.yml \
    -i inventory/prod/hosts \
    --vault-password-file password \
    -e lot-commander__application_repository_version=<branch name of lot-commander>
```

See also `run-playbooks.sh`, which runs `ec2-stack.yml` with variables loaded from `extra-vars.yml` (see `extra-vars.sample.yml` for the expected structure):

```
./run-playbooks.sh --dev    # or --prod, plus --check for a dry run
```

The script's `--vendor <name>` option (intended to run a client/vendor variant) is currently broken — it references files that don't exist in this repo. See `CLAUDE.md`.

### Packer

Packer was used to build AMIs for the lot-commander app server. The template is in `packer/app-server/template.pkr.hcl`. The provisioner runs the `app.yml` playbook to set up the server with all necessary dependencies and configuration for running lot-commander.

Build via

```
cd packer/app-server
packer build \
  -var "environment=<dev|prod>" \
  -var "version=<application version>" \
  -var "build_sha=<commit SHA of mimameith>" \
  -var "mimameith_version=<mimameith version>" \
  -var "ansible_roles_sha=<commit SHA of ansible roles>" \
  -var "ansible_roles_version=<ansible roles version>" \
  template.pkr.hcl
```

`environment` and `version` are required; the other variables have defaults but it's recommended to set them for better traceability of the built AMI. This was paired with `deploy-lot-commander.sh` at the repo root, which built the AMI, wrote its ID to SSM, and ran `terraform apply` plus an ASG instance refresh — see `CLAUDE.md` for why that script no longer works as-is.


