#! /usr/bin/env bash

# Tested on p7zip Version 16.02

_Main()
{
    declare __manifestFilepath="$1";
    shift;

    if [[ ! "$__manifestFilepath" =~ \.txt$ ]];
    then
        printf -- $'\n [-] Manifest file extension is not ".txt": \'%s\'.\n\n' "$__manifestFilepath";

        return 2;
    fi

    declare manifestFilepath;

    if ! manifestFilepath="$( readlink -en -- "$__manifestFilepath"; )" || [[ ! -r "$manifestFilepath" ]];
    then
        printf -- $'\n [-] Manifest file is not found or available: \'%s\'.\n\n' "$__manifestFilepath";

        return 2;
    fi

    # --------------------------------
    # Manifest directory
    # ----------------

    declare manifestDirpath;

    if ! manifestDirpath="$( dirname -- "$manifestFilepath"; )" || [[ ! -r "$manifestDirpath" ]];
    then
        printf -- $'\n [x] Manifest directory is not found or available: \'%s\'.\n\n' "$manifestFilepath";

        return 2;
    fi

    # Addon name
    # ----------------

    declare addonName;

    if ! addonName="$( basename -- "$manifestFilepath" '.txt'; )" || (( ! ${#addonName} ));
    then
        printf -- $'\n [x] Manifest filename is not found or available: \'%s\'.\n\n' "$manifestFilepath";

        return 2;
    fi

    # Addon version
    # ----------------

    declare version;

    if ! version="$( perl -ne 'print /^## Version:\s+([A-Za-z0-9\._-]+)$/' -- "$manifestFilepath"; )";
    then
        printf -- $'\n [-] Failed to find the version in manifest: \'%s\'.\n\n' "$manifestFilepath";

        return 1;
    fi

    # Find addon files
    # ----------------

    if ! readarray -td $'\n' -- files < <( perl -ne 'print if /^[^#\s]+/../EOF/' -- "$manifestFilepath"; ) || (( ! ${#files[@]} ));
    then
        printf -- $'\n [-] Failed to determine package files of manifest: \'%s\'.\n\n' "$manifestFilepath";

        return 1;
    fi

    # Add manifest file to be archived
    files+=( "${addonName}.txt" );

    # Create initial addon archive
    # ----------------

    declare archiveDirpath; archiveDirpath="$( pwd -P; )";

    pushd -- "$manifestDirpath" > /dev/null || return $?;

    declare archiveFilename="${addonName}_v${version}.zip";
    declare archiveFilepath; archiveFilepath="${archiveDirpath}/${archiveFilename}";

    if [[ -f "$archiveFilepath" ]];
    then
        printf -- $'\n [!] Addon archive already exists: \'%s\'.\n\n' "$archiveFilepath";

        return 1;
    fi

    declare rCode=0;

    if 7za a -r -t7z '-x!.git*' -bb0 -bso0 -- "$archiveFilepath" -- "${files[@]}"; (( rCode=$? ));
    then
        popd > /dev/null || return $?;

        printf -- $'\n [-] Failed to create archive (code %s): \'%s\'.\n\n' "$rCode" "$archiveFilepath";

        return "$rCode";
    fi

    popd > /dev/null || return $?;

    # Move addon archive files into internal subdirectory
    # ----------------

    declare archiveFiles=();

    readarray -t -- archiveFiles < <(
        set -o pipefail;

        7za l -t7z -slt -- "$archiveFilepath" | perl -ne 'print "$1\n" if /^Path = (.+)/';
    ) \
        || return $?;

    archiveFiles=( "${archiveFiles[@]:1}" );
    declare archiveFilesCount="${#archiveFiles[@]}";

    if (( ! archiveFilesCount ));
    then
        printf -- $'\n [x] No files found in the created initial archive: \'%s\'.\n\n' "$archiveFilepath";

        return 1;
    fi

    declare filepath;

    for filepath in "${archiveFiles[@]}";
    do
        if 7za rn -t7z -bb0 -bso0 -- "$archiveFilepath" "$filepath" "${addonName}/${filepath}"; (( rCode=$? ));
        then
            return "$rCode";
        fi
    done

    # Done
    # ----------------

    7za l -t7z -bb0 -bso0 -- "$archiveFilepath";
}

_Main "$@";
