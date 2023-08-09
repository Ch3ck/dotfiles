#!/bin/bash
set -euo pipefail

###########################################
# NOTE: MODIFY THIS SECTION TO
EMAIL="nyah@hey.com"
FIRST_NAME="Nyah"
LAST_NAME="Check"
###########################################

# Function to set up git credentials
setup_git() {
    git config --global user.name "${FIRST_NAME} ${LAST_NAME}"
    git config --global user.email "$EMAIL"
    echo "Git credentials have been set."
}

# Function to check if a GPG key exists
gpg_key_exists() {
    gpg --list-secret-keys --keyid-format=long | grep -q "${EMAIL}"
}

# Function to check if the SSH key exists on GitHub
ssh_key_exists_on_github() {
    gh ssh-key list | grep -q "${FIRST_NAME}-${LAST_NAME}-macbook-pro"
}

# Function to check if the GPG key exists on GitHub
gpg_key_exists_on_github() {
    gh gpg-key list | grep -q "${FIRST_NAME}-${LAST_NAME}-macbook-pro-16"
}

# Function to generate a new GPG key if one doesn't exist locally
generate_gpg_key() {
    echo "Setting Git and Generating GPG key..."
    setup_git

    if ! gpg_key_exists; then
        echo "No GPG key found. Generating a new GPG key..."
        gpg --batch --generate-key <<EOF
%echo Generating OpenPGP key
%no-protection
Key-Type: RSA
Key-Length: 4096
Name-Real: ${FIRST_NAME} ${LAST_NAME}
Name-Comment: GPG key for MacBook Pro 16
Name-Email: ${EMAIL}
Expire-Date: 2y
%commit
%echo done
EOF
    else
        echo "A GPG key already exists. Skipping GPG key generation."
    fi
}

# Function to install dependencies
install_deps() {
    brew upgrade gh terraform python3 protobuf npm go
    brew install pinentry-mac
    rustup update
    rustup default stable
}

# Function to install frontend tools (TypeScript, npm, Yarn)
install_frontend_tools() {
    echo " --- Installing Frontend Tools (TypeScript, npm, Yarn) --- "
    sudo npm install -g npm@latest typescript@latest yarn@latest
}

# Function to setup GitHub SSH and GPG keys
setup_github_keys() {
    # Authenticate with GitHub CLI
    echo " --- Running GitHub CLI setup ---"
    echo " --- Authenticating with GitHub via CLI --- "
   # gh auth login -p ssh --with-token <token.txt
    gh auth setup-git

    if ! ssh_key_exists_on_github; then
        echo " --- Setting up GitHub SSH key via gh CLI --- "
        ssh-keygen -t ed25519 -C "$EMAIL" -q -N ""
        eval "$(ssh-agent -s)"
        ssh-add ~/.ssh/id_ed25519
        gh ssh-key add -t "${FIRST_NAME}-${LAST_NAME}-macbook-pro" ~/.ssh/id_ed25519.pub
    else
        echo "An SSH key already exists on GitHub. Skipping SSH key export."
    fi

    if ! gpg_key_exists_on_github; then
        echo " --- Setting up GitHub GPG key via gh CLI --- "
        gpg_key_id=$(gpg --list-secret-keys --keyid-format=long | awk '/^sec/{print $2}' | awk -F'/' '{print $2; exit}')
        gpg --armor --export "${gpg_key_id}" | gh gpg-key add -t "${FIRST_NAME}-${LAST_NAME}-macbook-pro"
        git config --global user.signingkey "$gpg_key_id"
    else
        echo "A GPG key already exists on GitHub. Skipping GPG key export."
    fi
}

# Function to create shell alias files
create_dot_files() {
    for file in .{bash_aliases,bash_profile,gitconfig}; do
        echo "Creating $file"
        if [ -r "$file" ] && [ ! -f "$HOME/${file}" ]; then
            cp "$file" "$HOME/${file}"
        fi
    done
}

# Setup git and GPG keys
generate_gpg_key
setup_git

# Install dependencies
install_deps

# Install TypeScript and npm (if needed)
# install_frontend_tools

# Create bash files
create_dot_files

# Setup GitHub keys (GPG and SSH)
setup_github_keys
