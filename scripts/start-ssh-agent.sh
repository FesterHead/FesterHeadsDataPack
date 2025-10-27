#!/bin/bash

# SSH keys need to be loaded into an agent for Git to use them without
# prompting you for the passphrase every time.

# If your keys are named differently then use symlinks or modify this script.

# start ssh-agent if not already running
eval "$(ssh-agent -s)"

# add the github authentication key (you'll be prompted for the passphrase)
ssh-add ~/.ssh/github-authentication

# add the github signing key (you'll be prompted for the passphrase)
ssh-add ~/.ssh/github-signing

# verify the keys are loaded
ssh-add -l

echo "Pau. Have a great day! 🏄 🌈 🌴 🌺 🦄"
