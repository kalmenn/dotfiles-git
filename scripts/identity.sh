#!/bin/sh

if [ -z "$1" ]; then
    echo "USAGE:";
    echo "    git identity <gpg key id>";
    echo;

    echo "current identity:";
    echo "    name  = $(git config user.name)";
    echo "    email = $(git config user.email)";
    echo "    key   = $(git config user.signingKey)";
    exit 1;
fi

uid_regex="([^\(]*)\s*(\((.*)\))?\s*<(.*)>";

uid=$(gpg --with-colons -K $1 | awk -F: '$1=="uid" {print $10; exit}');

if [ -z "$uid" ]; then
    echo "ERROR: found no gpg key matching this";
    exit 1;
fi

name=$(printf "$uid" | sed --regexp-extended -e "s/$uid_regex/\1/");
email=$(printf "$uid" | sed --regexp-extended -e "s/$uid_regex/\4/");

echo "using this identity:";
echo "    name  = $name";
echo "    email = $email";

git config --local user.name "$name"
git config --local user.email "$email"

keyid=$(gpg -K --with-colon $1 | awk -F: '$12~/.*s.*/ {print $5; exit}');
# TODO: if multiple found, bring up a dialog to select the right key

if [ -z "$keyid" ]; then
    echo "WARNING: found no subkey with signing capabilities. No signing key will be set";
    git config --local --unset user.signingKey;
else
    echo "    key   = $keyid";
    git config --local user.signingKey "$keyid";
fi
