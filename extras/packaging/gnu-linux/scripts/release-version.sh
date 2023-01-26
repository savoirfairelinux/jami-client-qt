#!/bin/sh

if [ $# -gt 1 ]; then
    echo "Usage: $0 {stable,beta,nightly}"
    exit 1
fi

# default to stable if no release type given
release_type=${1:-stable}

last_commit_date=$(git log -1 --format=%cd --date=format:'%Y%m%d')
same_day_releases=$(git tag -l "${release_type}/${last_commit_date}*" | wc -l)
release_counter=${same_day_releases:-0}
release_version=${last_commit_date}.${release_counter}
printf "${release_version}"
