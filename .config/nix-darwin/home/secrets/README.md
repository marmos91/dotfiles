# Secrets Management with sops-nix

This directory contains encrypted secrets managed by [sops-nix](https://github.com/Mic92/sops-nix).

## Initial Setup

### 1. Generate an age key

#### Option A: Generate a standalone age key (recommended)

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt   # writes mode 0600 itself
```

Store a copy in 1Password as a document (it is the only key that can decrypt
`secrets.yaml`) and fetch it on any other machine with
`op document get "age-key" --out-file ~/.config/sops/age/keys.txt`.

#### Option B: Derive from your 1Password SSH key

This turns the 1Password-gated ed25519 key into a plaintext bearer file on disk:
the per-use approval prompt no longer applies, and any process running as you
can read it. Only do this if you accept that.

```bash
mkdir -p ~/.config/sops/age

# umask 077 so the file is never briefly world-readable; the redirect creates
# it before any later chmod could run.
( umask 077; ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt )
chmod 600 ~/.config/sops/age/keys.txt

# Get the age public key for .sops.yaml
ssh-to-age -i ~/.ssh/id_ed25519.pub
```

The key file must stay at mode 0600: activation refuses to rebuild when it is
missing or group/world-readable.

### 2. Create the .sops.yaml configuration

`.sops.yaml` is committed. Put your age public key (`age-keygen -y
~/.config/sops/age/keys.txt`) in it:

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

`secrets.yaml` is only ever created by an encrypting command. Never `cp` it
into place — a plaintext copy at that path is staged by the next `git add -A`,
and the blob stays in history forever.

```bash
cd ~/.dotfiles/.config/nix-darwin/home/secrets

# Edit a throwaway copy outside the repo, then encrypt into the real path.
# The temp copy is named secrets.yaml because .sops.yaml's creation rule is
# path_regex: secrets\.yaml$ — a bare mktemp name has no key group.
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
cp secrets.yaml.template "$d/secrets.yaml"
$EDITOR "$d/secrets.yaml"
sops --encrypt --config .sops.yaml "$d/secrets.yaml" > secrets.yaml
```

A pre-commit guard rejects a staged `secrets.yaml` that carries no `ENC[` data
block, so a plaintext file cannot be committed even by accident.

### 4. Rebuild your system

```bash
rebuild
```

## Managing Secrets

### Edit encrypted secrets

```bash
# Opens decrypted in $EDITOR, re-encrypts on save
sops secrets.yaml

# Or one key at a time (atomic, and the plaintext temp copy is trapped)
secrets edit <key>
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

### Option A: Copy the standalone key (recommended)

Fetch the age key from 1Password — the same key works on every machine:

```bash
mkdir -p ~/.config/sops/age
op document get "age-key" --out-file ~/.config/sops/age/keys.txt
chmod 600 ~/.config/sops/age/keys.txt
```

### Option B: Derive from the same SSH key

If you used the SSH derivation approach, derive it again on the new machine
(same `umask 077` redirect as step 1):

```bash
mkdir -p ~/.config/sops/age
( umask 077; ssh-to-age -private-key -i ~/.ssh/id_ed25519 > ~/.config/sops/age/keys.txt )
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

**Backup recipient is a deliberate gap.** `.sops.yaml` ships a single
recipient: the repo cannot manufacture a second age key, so there is currently
no backup recipient that survives losing the primary key. To close it, run
`age-keygen`, add the public key as `&secondary` in `.sops.yaml`, and run
`sops updatekeys secrets.yaml`.

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
- **Always commit** the encrypted `secrets.yaml`, and only ever create it with
  an encrypting command
- Decrypted values are plaintext files (mode 0600) in sops-nix's secrets
  mount, `%r/secrets.d/<generation>/`: on macOS that is the per-user temp
  dir under `/var/folders/` (`getconf DARWIN_USER_TEMP_DIR`), on Linux
  `/run/user/$(id -u)/secrets.d/`. `~/.config/sops-nix/secrets` links to the
  current generation, and every `$HOME` target in the table below (plus the
  rendered templates `~/.config/mcp/mcp.json` and `~/.pi/agent/models.json`)
  is a symlink into it. Backing up or syncing the symlinks copies no
  secret; the plaintext is wherever the temp dir is (on disk on macOS,
  so treat it as exposed if the disk is stolen). macOS can purge that dir;
  `rebuild` re-creates it.

- **Tool-writable files are reverted on rebuild.** `~/.kube/config` and
  `~/.aws/*` are whole files rendered from `secrets.yaml`, so
  `kubectl config use-context`, `aws configure set` and `aws sso login` write
  into a generation the next `rebuild` replaces. Mirror any such change into
  `secrets.yaml` (`secrets edit <key>`) first; the file on disk is not the
  durable copy.

## Configured Secrets

This table mirrors `default.nix`; when they disagree, `default.nix` wins.

| Secret | Target Path | Description |
|--------|-------------|-------------|
| `kubeconfig` | `~/.kube/config` | Kubernetes configuration |
| `aws_credentials` | `~/.aws/credentials` | AWS access keys |
| `aws_config` | `~/.aws/config` | AWS CLI configuration |
| `rclone_config` | `~/.config/rclone/rclone.conf` | Rclone remote configuration |
| `ssh_hosts_config` | `~/.ssh/config.d/hosts` | SSH hosts with mnemonic names |
| `mimir_api_key` | `~/.config/opencode/mimir-key` | Mimir gateway API key |
| `mimir_base_url` | `~/.config/opencode/mimir-base-url` | Internal Mimir endpoint |
| `google_docs_mcp_client_id` | `~/.config/google-docs-mcp/client-id` | Google OAuth client id |
| `google_docs_mcp_client_secret` | `~/.config/google-docs-mcp/client-secret` | Google OAuth client secret |
| `ds3ctl_config` | `~/.config/ds3ctl/config.yaml` | ds3ctl configuration |
| `git_identity` | `~/.config/git/identity` | Personal git identity |
| `git_identity_work` | `~/.config/git/identity-work` | Work git identity |
| `git_allowed_signers` | `~/.config/git/allowed_signers` | SSH signing trust list |
| `gcal_client_id` | `~/.config/gcal-personal-block/client-id` | GCP OAuth client id (gcal-personal-block) |
| `gcal_client_secret` | `~/.config/gcal-personal-block/client-secret` | GCP OAuth client secret (gcal-personal-block) |
| `gcal_family_cal` | `~/.config/gcal-personal-block/family-cal` | Source Family calendar id |
| `gcal_work_email` | `~/.config/gcal-personal-block/work-email` | Work account to receive mirror blocks |
