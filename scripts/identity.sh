#!/bin/sh

identities="$HOME/.local/share/git/identities";

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

    git config -f "$filepath" user.name "$name"
    git config -f "$filepath" user.email "$email"

    local keyid=$(gpg -K --with-colon $1 | awk -F: '$12~/.*s.*/ {print $5; exit}');
    # TODO: if multiple found, bring up a dialog to select the right key

    if [ -z "$keyid" ]; then
        echo "WARNING: found no subkey with signing capabilities. No signing key will be set";
        git config -f "$filepath" --unset user.signingKey;
    else
        git config -f "$filepath" user.signingKey "$keyid";
    fi
}

case $1 in
    import)
        if [ -z "$2" ]; then
            echo "USAGE:";
            echo "    git identity import <gpg_key_id> [identity_file_name]"
            echo;
            echo "Imports an identity from a gpg key. If no filename is provided, it will by default to the identifier you provided for your gpg key"
            exit 1;
        fi

        if [ -z "$3" ]; then
            import_identity "$2" "$2";
        else
            import_identity "$2" "$3";
        fi

        echo "imported into $filepath:"
        cat "$filepath";
    ;;
    *)
        echo "USAGE:";
        echo "    git identity <command>";
        echo;
        echo "COMMANDS:"
        echo "    import: import an identity from a gpg key"
        echo "    remove: removed a saved identity";
        echo "    set: sets the identity of the current git repo"
        echo "    show: show a saved identity or the identity of the current repo"
        echo "    list: list all saved identities"
        exit 1;
    ;;
esac
