# Ansible deployment for Lot Commander
Playbooks and roles for deploying Lot Commander application stack. See below for detailed playbook descriptions. 
Contains secret file(s) encrypted with `ansible-vault`.

## Vagrant

A `Vagrantfile` is included to spin up virtual machines for local use. It uses the same ansible playbooks from production for setting up the provisioned VMs (obviously without the ). A full development stack is available, including its various intranet connections.

There are also control machines which are not part of the stack but useful for performing maintenance tasks on other servers.

Inventory host and variable files are in `inventory/vagrant`.

## Secrets

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

### Inline encryption

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

### Password 

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

### Session cookie secret

To generate a new secret for session cookies, replace the `session_secret` field in `secrets.yml` with the result of

```
head -c20 /dev/urandom | base64
```

This should be done semi-regularly. Note that old sessions will not be valid on servers instantiated with the new secret.