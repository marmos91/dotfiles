# Secrets Management with sops-nix

This directory contains encrypted secrets managed by [sops-nix](https://github.com/Mic92/sops-nix).

## Initial Setup

### 1. Generate an age key

You have two options:

#### Option A: Derive from SSH key (recommended if using 1Password SSH)

If you have an ed25519 SSH key (e.g., managed by 1Password):

```bash
mkdir -p ~/.config/sops/age

# Convert your SSH private key to an age key
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt

# Get the age public key for .sops.yaml
ssh-to-age -i ~/.ssh/id_ed25519.pub
```

#### Option B: Generate a standalone age key

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
```

Save the public key (starts with `age1...`) - you'll need it for encryption.

### 2. Create the .sops.yaml configuration

Create `.sops.yaml` in this directory:

```yaml
keys:
  - &primary age1your_public_key_here

creation_rules:
  - path_regex: secrets\.yaml$
    key_groups:
      - age:
          - *primary
```

### 3. Create and encrypt your secrets

```bash
# Copy the template
cp secrets.yaml.template secrets.yaml

# Edit with your actual secrets
$EDITOR secrets.yaml

# Encrypt in place
sops -e -i secrets.yaml
```

### 4. Rebuild your system

```bash
rebuild
```

## Managing Secrets

### Edit encrypted secrets

```bash
# Opens decrypted in $EDITOR, re-encrypts on save
sops secrets.yaml
```

### Add a new secret

1. Edit `default.nix` to add the secret definition
2. Edit `secrets.yaml` (via `sops secrets.yaml`) to add the value
3. Run `rebuild`

### View decrypted secrets

```bash
sops -d secrets.yaml
```

## Adding Another Machine

### Option A: Derive from same SSH key (recommended with 1Password)

If you used the SSH key approach, just derive the age key again on the new machine:

```bash
mkdir -p ~/.config/sops/age
ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

Since 1Password syncs your SSH key everywhere, this automatically works on all machines.

### Option B: Fetch from 1Password

If you stored the age key in 1Password:

```bash
mkdir -p ~/.config/sops/age
op document get "age-key" --out-file ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

### Option C: Separate key per machine (more secure)

1. Generate a new age key on that machine
2. Add the new public key to `.sops.yaml`:
   ```yaml
   keys:
     - &primary age1xxx...   # Main machine
     - &secondary age1yyy... # New machine

   creation_rules:
     - path_regex: secrets\.yaml$
       key_groups:
         - age:
             - *primary
             - *secondary
   ```
3. Re-encrypt secrets with all keys:
   ```bash
   sops updatekeys secrets.yaml
   ```

## File Structure

```
secrets/
├── default.nix           # Nix module defining secrets
├── secrets.yaml          # Encrypted secrets (commit this)
├── secrets.yaml.template # Template showing structure (commit this)
├── .sops.yaml            # SOPS configuration (commit this)
└── README.md             # This file
```

## Security Notes

- **Never commit** `~/.config/sops/age/keys.txt` - this is your private key
- **Always commit** the encrypted `secrets.yaml`
- Secrets are decrypted at activation time and stored in a secure location
- On macOS: secrets go to a temp directory under `/var/folders/`
- On Linux: secrets go to `/run/user/$(id -u)/secrets/`

## Configured Secrets

| Secret | Target Path | Description |
|--------|-------------|-------------|
| `kubeconfig` | `~/.kube/config` | Kubernetes configuration |
| `aws_credentials` | `~/.aws/credentials` | AWS access keys |
| `aws_config` | `~/.aws/config` | AWS CLI configuration |
| `rclone_config` | `~/.config/rclone/rclone.conf` | Rclone remote configuration |
