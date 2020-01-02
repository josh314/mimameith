# Ansible deployment for Lot Commander
Playbooks and roles for deploying Lot Commander application. Hosts file is untracked. Contains a `secrets.yml` that is encrypted with `ansible-vault`.

Usage:

`ansible-playbook app.yml -i hosts.yml --ask-vault-password`

or

`ansible-playbook app.yml -i hosts.yml --vault-password-file /path/to/password.txt`

If `/path/to/password.txt` has the executable-bit set, then Ansible will execute it and use the contents of `stdout` as the vault password.

## Secrets

The encrypted, password-protected `secrets.yml` file is managed by `ansible-vault`. You can view the file with

`ansible-vault view secrets.yml`.

To modify `secrets.yml`, open the file with `ansible-vault` (this will use the host $EDITOR):

`ansible-vault edit secrets.yml`.

Alternately, first decrypt:

`ansible-vault decrypt secrets.yml`,

then make your edits in the text editor of your choice. When you are finished editting, re-encrypt:

`ansible-vault encrypt secrets.yml`.

When decrypting/re-encrypting, you actually setting a new password at the second stage so you will have to input the password twice for confirmation. See the help for `ansible-vault` for more options.