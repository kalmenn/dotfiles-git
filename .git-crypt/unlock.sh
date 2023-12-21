#!/bin/sh

# Use this script to decrypt the repo ~manually~.
# This is necessary because cloning it in ~/.config/git will leave your git
# config broken until the repo is decrypted.
# However, decrypting with git-crypt unlock is not possible without a working
# git config (it needs it to figure out which gpg key to use for decrypting)

git_crypt_key="/tmp/git-crypt_key.tmp";

gpg --decrypt ~/.config/git/.git-crypt/keys/default/0/6413A51F72B1C87D07C161F4DFF253360BF8471F.gpg > "$git_crypt_key"
HOME= git crypt unlock "$git_crypt_key"
shred -u "$git_crypt_key"
