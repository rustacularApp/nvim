Here is a complete command-by-command cheat sheet for **fnox**, organized directly around the workflows you asked for plus the other everyday commands you'll need.

---

### 1. Insert a single secret (`fnox set`)
*(Alias: `fnox s`)*

```sh
# Safest: prompts for the value with hidden input (keeps it out of shell history)
fnox set DATABASE_URL

# Inline value
fnox set DATABASE_URL "postgresql://localhost/mydb"

# Specify a provider (if not using default_provider)
fnox set DATABASE_URL --provider age
fnox set API_KEY --provider aws --key-name custom-remote-name

# Store exact file contents (preserves trailing newlines, great for certs/SSH keys)
fnox set SSH_PRIVATE_KEY --from-file ~/.ssh/id_ed25519

# Auto-generate a random secret (password | hex | base64 | uuid)
fnox set API_TOKEN --generate
fnox set SESSION_KEY --generate --generate-type hex --length 64 --show

# Insert into a specific profile or your global config (~/.config/fnox/config.toml)
fnox set DATABASE_URL -P staging
fnox set GITHUB_TOKEN --global
```
*(Tip: `fnox set KEY --url https://...` saves a token rotation URL, and `fnox set KEY --open` opens that URL in your browser and prompts for the new value.)*

---

### 2. Update a single secret (`fnox set` / `fnox edit`)

* **Update via CLI (`fnox set`):** Run `fnox set` again. Note that replacing an existing secret uses `--force` (`-f`):
  ```sh
  fnox set DATABASE_URL --force
  fnox set API_TOKEN --generate --force
  fnox set DATABASE_URL "new_value" -P staging --force
  ```
* **Update interactively in your `$EDITOR` (`fnox edit KEY`):**
  Decrypts **only** that one secret into a temporary buffer, opens your `$EDITOR`, and re-encrypts/saves it on exit (preserving other settings and without decrypting other secrets):
  ```sh
  fnox edit DATABASE_URL
  fnox edit DATABASE_URL -P production
  ```

---

### 3. Bulk insert secrets (`fnox import` / `fnox edit`)
*(Alias: `fnox im`)*

**Option A: Import from `.env`, JSON, YAML, or TOML (`fnox import`)**  
*(Requires an encryption provider like `age`, `aws-kms`, `yubikey`, or `fido2` — remote vaults like 1Password aren't import targets.)*

```sh
# Preview what will be imported first (dry run)
fnox import -i .env --provider age --dry-run

# Import everything from .env
fnox import -i .env --provider age

# Import from JSON, YAML, or TOML (flat key-value map)
fnox import -i secrets.json json --provider age
fnox import -i secrets.yaml yaml --provider age
fnox import -i secrets.toml toml --provider age

# Pipe from stdin (requires --force since stdin can't answer prompts)
cat .env | fnox import --provider age --force

# Filter by regex or add a prefix during import
fnox import -i .env --provider age --filter '^DATABASE_' --prefix 'LEGACY_'

# Import into a specific profile or global config
fnox import -i .env.staging --provider age -P staging
fnox import -i .env --provider age --global
```

**Option B: Interactive bulk add (`fnox edit`)**  
Run `fnox edit` with no key name to open all decrypted secrets across the config in `$EDITOR`, paste/add as many new entries as you want, and save/exit to encrypt them all.

---

### 4. Bulk update secrets (`fnox edit` / `fnox import` / `fnox reencrypt`)

* **Interactive bulk edit (`fnox edit`):**
  ```sh
  # Decrypts all secrets into a temp file in $EDITOR ($VISUAL, vi, or notepad).
  # Every added or modified value is re-encrypted/written back on save & exit.
  fnox edit
  ```
* **Bulk overwrite from a file (`fnox import --force`):**
  ```sh
  # Updates matching keys from an updated .env / json / yaml / toml file without prompting
  fnox import -i updated.env --provider age --force
  ```
* **Bulk key rotation / recipient update (`fnox reencrypt`):**
  *(When you add/remove an `age` public key in `recipients` or change a KMS key, re-encrypts all existing ciphertext without changing values.)*
  ```sh
  fnox reencrypt -p age --dry-run   # preview
  fnox reencrypt -p age             # re-encrypt active profile
  fnox reencrypt -p age -P staging  # re-encrypt another profile
  ```
* **Bulk cache or push elsewhere:**
  ```sh
  fnox sync -p age --local-file     # Bulk-cache remote secrets locally (encrypted)
  fnox push                         # Bulk-push secrets to write-only targets (GitHub Actions, Vercel, etc.)
  ```

---

### 5. View a single secret (`fnox get`)

```sh
# Print the resolved plaintext value to stdout
fnox get DATABASE_URL

# From a specific profile
fnox get DATABASE_URL -P staging

# View a stored secret file
fnox get --file ~/.kube/config
```
*(Note: If the secret has `as_file = true`, `fnox get` prints the path to the temporary file holding the value.)*

---

### 6. View 2 or 3 specific secrets (`fnox export` / `fnox env`)

`fnox get` only accepts one key, so to view a few specific variables at once, pass their names to **`fnox export`** (alias: `fnox ex`):

```sh
# Print just those 2 or 3 secrets in KEY=value format
# (Only resolves those keys — skips other provider calls/auth prompts)
fnox export DATABASE_URL STRIPE_KEY JWT_SECRET

# Same, formatted as JSON, YAML, TOML, or shell exports
fnox export -f json DATABASE_URL STRIPE_KEY
fnox export -f yaml DATABASE_URL STRIPE_KEY

# From a specific profile
fnox -P production export DATABASE_URL STRIPE_KEY

# Machine-readable JSON output for an exact comma-separated list
fnox env --json --keys DATABASE_URL,STRIPE_KEY
```

---

### 7. View all secrets & metadata (`fnox list` / `fnox tui` / `fnox export`)

* **Table overview (`fnox list`, aliases: `ls`, `secrets`):**
  ```sh
  fnox list              # List keys, providers, and descriptions (does NOT decrypt values)
  fnox list --values     # (-V) Resolve and display every secret's actual value
  fnox list --sources    # (-s) Show which config file defines each key
  fnox list --full       # (-f) Don't truncate provider keys at 40 chars
  fnox -P prod list      # List another profile's secrets
  fnox -P aws,prod list  # Layer multiple profiles
  ```
* **Interactive dashboard (`fnox tui`):**
  ```sh
  fnox tui   # Full-screen TUI to filter, switch profiles, reveal, and copy values (read-only)
  ```
* **Dump all values (`fnox export`):**
  ```sh
  fnox export               # All env-eligible secrets as KEY=value
  fnox export --all         # Include env = false and env = "exec" secrets
  fnox export -f json       # JSON format (also: shell, yaml, toml)
  (umask 077 && fnox export -o .env)   # Write to a private .env file
  ```

---

### 8. Other essential daily commands

#### Run commands with secrets (`fnox exec`, alias `fnox x`)
```sh
fnox exec -- npm start
fnox -P production exec --if-missing error -- ./deploy.sh
fnox exec --only DATABASE_URL,'AWS_*' -- ./migrate.sh   # Resolve only matching secrets/globs
fnox exec --except LEGACY_KEY -- npm start              # Skip specific secrets
fnox exec --refresh API_TOKEN -- ./script.sh            # Bypass daemon cache for one key
```

#### Delete & rename secrets
```sh
fnox remove OLD_KEY            # (aliases: rm, delete) Removes key from fnox.toml (not remote vault)
fnox rename OLD_KEY NEW_KEY    # Renames key in config (supports --dry-run / -n and --global / -g)
```

#### Validate, troubleshoot & prevent leaks
```sh
fnox check --all               # Verify all secrets resolve/decrypt without printing values
fnox doctor                    # (alias: dr) Validate config, profiles, and test provider connections
fnox scan                      # Scan directory for leaked plaintext secrets
fnox scan --values --staged    # Check git-staged files for real secret values
fnox scan --install-hook       # Install git pre-commit hook to block secret leaks
```

#### Config, profiles, providers & shell integration
```sh
fnox profiles                  # List available profiles and secret counts
fnox config-files              # Show loaded config files in hierarchy order
fnox provider list             # List configured providers
fnox provider test -a          # Test all provider connections
fnox provider discover <PROV>  # Browse remote items (e.g., 1Password) without reading secret values
fnox activate zsh              # Add `eval "$(fnox activate zsh)"` to ~/.zshrc for auto-loading on cd
fnox deactivate                # Turn off shell auto-loading in current shell
fnox daemon status             # Check/manage in-memory secret cache (start | stop | clear)
```

#### Useful global flags (put **before** the subcommand)
* `-P <PROFILE>` / `--profile <PROFILE>`: Select or layer profiles (e.g. `fnox -P aws,staging list`).
* `-c <PATH>` / `--config <PATH>`: Load a specific config file.
* `--walk-up`: Make write commands (`set`, `remove`, `rename`, `import`) modify the nearest parent `fnox.toml` instead of creating one in the current directory.
* `--write-profile <PROFILE>`: Choose which profile gets modified when multiple profiles are active.
* `--no-daemon`: Bypass the memory cache for one command.
* `--non-interactive`: Never prompt or open a browser (good for CI).
