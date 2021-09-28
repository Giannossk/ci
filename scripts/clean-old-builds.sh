#!/bin/bash
set -o errexit # Exit on error

usage() {
    echo "Usage: clean-old-builds.sh <directories-to-clean>"
}

last-edit() {
    check_dir="$1"
    mode="$2"

    # check last build date
    now_epoch="$(date +%s)"
    if vm-is-macos && stat -f "%Sm" $check_dir > /dev/null 2>&1; then
        lastedit_date="$(stat -f "%Sm" $check_dir)"
        lastedit_epoch="$(stat -f "%m" $check_dir)"
    else
        lastedit_date="$(date -r $check_dir)"
        lastedit_epoch="$(date +%s -r $check_dir)"
    fi

    check_delta=$(( now_epoch - lastedit_epoch )) # in seconds

    if [[ "$mode" == "date" ]]; then
        echo "$lastedit_date"
    elif [[ "$mode" == "seconds" ]]; then
        echo "$check_delta"
    fi
}

if [ "$#" -gt 0 ]; then
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    . "$SCRIPT_DIR"/utils.sh
    . "$SCRIPT_DIR"/github.sh
else
    usage; exit 1
fi

load-vm-env

BASE_DIR="$(pwd)"

free_space="$(df -P . | tail -1 | awk '{print $4}')"
if [ "$free_space" -lt 5242880 ]; then
    # less than 5 GB
    MAX_DAYS_SINCE_MODIFIED_SHORT=1/5
    MAX_DAYS_SINCE_MODIFIED_LONG=3/2
elif [ "$free_space" -lt 10485760 ]; then
    # less than 10 GB
    MAX_DAYS_SINCE_MODIFIED_SHORT=1/4
    MAX_DAYS_SINCE_MODIFIED_LONG=3
else
    MAX_DAYS_SINCE_MODIFIED_SHORT=1/2
    MAX_DAYS_SINCE_MODIFIED_LONG=6
fi
max_sec_since_modified_short=$(( 3600 * 24 * $MAX_DAYS_SINCE_MODIFIED_SHORT ))
max_sec_since_modified_long=$(( 3600 * 24 * $MAX_DAYS_SINCE_MODIFIED_LONG ))
echo "------------------"
echo "free_space = $free_space"
echo "MAX_DAYS_SINCE_MODIFIED_SHORT = $MAX_DAYS_SINCE_MODIFIED_SHORT"
echo "MAX_DAYS_SINCE_MODIFIED_LONG = $MAX_DAYS_SINCE_MODIFIED_LONG"
echo "------------------"

for build_dir in "$@"; do
    cd "$BASE_DIR"
    if [ ! -d "$build_dir" ]; then
        continue
    fi

    echo "" # newline
    echo "Cleaning in $build_dir"

    cd "$build_dir"
    for dir in *; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        echo "  $dir:"

        if [[ "$dir" == "PR-"* ]]; then # PR dir
            # check if this PR is closed
            pr_id="${dir#*-}"
            pr_state="$(github-get-pr-state "$pr_id")"
            if [[ "$pr_state" == "closed" ]]; then
                echo "    PR $pr_id is closed"
                echo "    -> removed"
                rm -rf "$dir"
                continue
            fi
        fi

        MAX_DAYS_SINCE_MODIFIED="$MAX_DAYS_SINCE_MODIFIED_LONG"
        max_sec_since_modified="$max_sec_since_modified_long"

        if [[ "$build_dir/" == *"/launcher/"* ]]; then
            # Launcher has no config/build, only sources
            echo "  Launcher detected."
            delta="$(last-edit "$dir" "seconds")"
            lastedit_date="$(last-edit "$dir" "date")"
            echo -n "    last launch: $lastedit_date"
            if [ "$delta" -gt $max_sec_since_modified ]; then
                echo "   (more than $MAX_DAYS_SINCE_MODIFIED days ago)"
                echo "    -> removed"
                rm -rf "$dir"
            else
                echo "" # newline
                echo "    -> not removed"
            fi
        else
            cd "$dir"

            if [[ "$build_dir/" != *"/sofa-framework/"* ]]; then
                MAX_DAYS_SINCE_MODIFIED="$MAX_DAYS_SINCE_MODIFIED_SHORT"
                max_sec_since_modified="$max_sec_since_modified_short"
            fi

            all_configs_removed="true"
            for config in *; do
                if [ ! -d "$config" ] || [[ "$config" == *"tmp" ]] || [ ! -d "$config/src/SofaKernel" ]; then
                    continue
                fi
                echo "    $config:"
                if [ -d "$config/build" ]; then
                    rm -f $config/build/core.* # remove eventual coredump files
                    delta="$(last-edit "$config/build" "seconds")"
                    lastedit_date="$(last-edit "$config/build" "date")"
                    echo -n "      last build was on $lastedit_date"
                    if [ "$delta" -gt $max_sec_since_modified ]; then
                        echo "   (more than $MAX_DAYS_SINCE_MODIFIED days ago)"
                        echo "      -> removed"
                        rm -rf "$config"
                    else
                        echo "" # newline
                        echo "      -> not removed"
                        all_configs_removed="false"
                    fi
                else
                    echo "    $config: no build dir"
                fi
            done
            cd ..
            if [[ "$all_configs_removed" == "true" ]]; then
                echo "    All valid configs were removed"
                echo "    -> $dir removed"
                rm -rf "$dir"
            fi
        fi
    done
done

# Clean Docker
if [ -e "$(command -v docker)" ]; then
    echo "" && echo ""
    echo "Cleaning Docker containers and images..."
    docker system prune -a -f || true
fi
