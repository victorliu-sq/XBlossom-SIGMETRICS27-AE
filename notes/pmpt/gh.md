# Install and set up GitHub CLI (`gh`)

Use this when a setup step asks for GitHub CLI authentication, or when `gh auth status` says the GitHub CLI is not logged in.

## 1. Install `gh`

Ubuntu/Debian:

```bash
sudo apt update
sudo apt install gh
```

If the distro package is missing or too old, use the official GitHub CLI package repository from:

```text
https://github.com/cli/cli/blob/trunk/docs/install_linux.md
```

macOS:

```bash
brew install gh
```

Check the install:

```bash
gh --version
```

## 2. Make sure SSH exists

Check for an existing public key:

```bash
ls ~/.ssh/*.pub
```

If there is no key, create one:

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Use the default path unless you have a reason to manage multiple keys.

## 3. Log in with browser auth

Run:

```bash
gh auth login
```

Recommended answers for this workflow:

```text
What account do you want to log into? GitHub.com
What is your preferred protocol for Git operations on this host? SSH
Upload your SSH public key to your GitHub account? ~/.ssh/id_ed25519.pub
Title for your SSH key: GitHub CLI
How would you like to authenticate GitHub CLI? Login with a web browser
```

`gh` will print a one-time code and ask you to press Enter to open GitHub in a browser. Copy the code into the browser page, approve the login, then return to the terminal.

A successful setup looks like:

```text
Authentication complete.
Configured git protocol
Uploaded the SSH key to your GitHub account
Logged in as <github-user>
```

## 4. Avoid the bad-token path unless needed

The screenshot shows this failure:

```text
error validating token: HTTP 401: Bad credentials
```

That means the pasted Personal Access Token was invalid, expired, revoked, or missing required scopes. For normal local setup, choose `Login with a web browser` instead.

If token auth is required, create a fresh token at:

```text
https://github.com/settings/tokens
```

The prompt lists the minimum scopes it needs, commonly:

```text
repo, read:org, admin:public_key
```

Then rerun:

```bash
gh auth login
```

## 5. Verify GitHub access

Check `gh` auth:

```bash
gh auth status
```

Check SSH auth to GitHub:

```bash
ssh -T git@github.com
```

Check the Git protocol preference:

```bash
gh config get git_protocol -h github.com
```

It should print:

```text
ssh
```

If needed, set it manually:

```bash
gh config set -h github.com git_protocol ssh
```
