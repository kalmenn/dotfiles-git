#!/bin/sh

identities="$HOME/.local/share/git/identities";
mkdir -p "$identities";

function yes_or_no { # courtesy of: https://stackoverflow.com/a/29436423
    while true; do
        read -p "$* [y/n]: " yn;
        case $yn in
            [Yy]*) return 0 ;;
            [Nn]*) return 1 ;;
        esac
    done
}

function get_identity() {
    filepath="$identities/$1";
    identity="$1"; # TODO: match from partial names and set this to the correct one
    sigkey=$(git config -f "$filepath" user.signingKey);
    name=$(git config -f "$filepath" user.name);
    email=$(git config -f "$filepath" user.email);
}

function display_parts() {
    local identity="$1";
    local name="$2";
    local email="$3";
    local sigkey="$4";

    printf "[$identity] $name <$email>";
    if [ ! -z $sigkey ]; then
        printf " (signing key: $sigkey)";
    fi
    printf "\n";
}

function display_identity() {
    local name email sigkey;
    get_identity $1;
    display_parts "$identity" "$name" "$email" "$sigkey";
}

function import_identity() {
    local gpg_key_id="$1"
    filepath="$identities/$2";

    local uid_regex="([^\(]* )\s*(\((.*)\))?\s*<(.*)>";

    local uid=$(gpg --with-colons -K $gpg_key_id | awk -F: '$1=="uid" {print $10; exit}');

    if [ -z "$uid" ]; then
        echo "ERROR: found no gpg key matching this";
        exit 1;
    fi

    local name=$(printf "$uid" | sed -Ee "s/$uid_regex/\1/" | xargs);
    local email=$(printf "$uid" | sed -Ee "s/$uid_regex/\4/");

    git config -f "$filepath" user.name "$name";
    git config -f "$filepath" user.email "$email";

    local keyid=$(gpg -K --with-colon $1 | awk -F: '$12~/.*s.*/ {print $5; exit}');
    # TODO: if multiple found, bring up a dialog to select the right key

    if [ -z "$keyid" ]; then
        echo "WARNING: found no subkey with signing capabilities. No signing key will be set";
        git config -f "$filepath" --unset user.signingKey;
    else
        git config -f "$filepath" user.signingKey "$keyid";
    fi
}

function list_identities() {
    if [ -z "$(ls -A "$identities")" ]; then
        echo "no identities to display";
        exit 0;
    fi
    local sigkey name email;
    for id_file in $identities/*; do
        identity="$(basename "$id_file")";
        get_identity "$identity";
        display_parts "$identity" "$name" "$email" "$sigkey";
    done
}

case $1 in
    import)
        if [ -z "$2" ]; then
            echo "USAGE:";
            echo "    git identity import <gpg_key_id> [identity_file_name]";
            echo;
            echo "Imports an identity from a gpg key. If no filename is provided, it will by default to the identifier you provided for your gpg key";
            exit 1;
        fi

        if [ -z "$3" ]; then
            identity="$2";
        else
            identity="$3";
        fi
        import_identity "$2" "$identity";

        echo "imported into $filepath :"
        display_identity "$identity";
    ;;
    remove)
        if [ -z "$2" ]; then
            echo "USAGE:";
            echo "    git identity remove <identity>";
            echo;
            echo "Removes a saved identity. This is unrecoverable; You'll need to re-import / add it yourself again.";
            exit 1;
        fi

        get_identity "$2";

        display_identity "$identity";
        yes_or_no "Are you sure ou want to remove this identity ?" && rm "$filepath";
    ;;
    list)
        list_identities;
    ;;
    *)
        echo "USAGE:";
        echo "    git identity <command>";
        echo;
        echo "Saved identities can be found here: $identities";
        echo;
        echo "COMMANDS:";
        echo "    import: import an identity from a gpg key";
        echo "    remove: removes a saved identity";
        echo "    set: sets the identity of the current git repo";
        echo "    link: links the global identity file to your current git repo.";
        echo "    show: show a saved identity or the identity of the current repo";
        echo "    list: list all saved identities";
        exit 1;
    ;;
esac
