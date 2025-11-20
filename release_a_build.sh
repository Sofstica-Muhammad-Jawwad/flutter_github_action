#!/bin/sh

function info() {
    cat <<EOF

    Please enter [1] [2] [3] for required version increment

    For Major Increment: 1
    For Minor Increment: 2
    For Patch Increment: 3

EOF
}

function error() {
    red='\033[0;31m'
    echo ${red}Invalid Argument: Please run the command with a valid option${red}
}

info

yellow='\033[0;33m'
clear='\033[0m'

echo $yellow
read -p "Enter your choice: " input
echo ''
echo $clear

function incrementIosVersion() {
    ios_file="ios/Runner.xcodeproj/project.pbxproj"

    existing_version_ios=$(grep MARKETING_VERSION "$ios_file" | head -1 | awk -F ' = ' '{print $2}' | sed 's/;//g')
    existing_code_ios=$(grep CURRENT_PROJECT_VERSION "$ios_file" | head -1 | awk -F ' = ' '{print $2}' | sed 's/;//g')

    existing_code_ios=${existing_code_ios:-0}
    new_code_ios=$existing_code_ios
    let "new_code_ios++"

    major=$(echo $existing_version_ios | awk -F '.' '{print $1}')
    minor=$(echo $existing_version_ios | awk -F '.' '{print $2}')
    patch=$(echo $existing_version_ios | awk -F '.' '{print $3}')

    if [ "$1" = '1' ]; then
        let "major++"
        minor=0
        patch=0
    elif [ "$1" = '2' ]; then
        let "minor++"
        patch=0
    elif [ "$1" = '3' ]; then
        let "patch++"
    fi

    new_version_ios=${major}.${minor}.${patch}

    sed "s/MARKETING_VERSION = ${existing_version_ios}/MARKETING_VERSION = ${new_version_ios}/g" "$ios_file" > ios_version_number
    sed "s/CURRENT_PROJECT_VERSION = ${existing_code_ios}/CURRENT_PROJECT_VERSION = ${new_code_ios}/g" ios_version_number > ios_version_code
    cat ios_version_code > "$ios_file"
    rm ios_version_code ios_version_number

    green='\033[0;32m'
    echo "${green}iOS Version updated successfully!${clear}"
}

function incrementAndroidVersion() {
    existing_version_with_code=$(grep version: pubspec.yaml | awk -F 'version:' '{print $2}' | sed 's/ //g')

    if ! echo "$existing_version_with_code" | grep -q '+'; then
        existing_version_with_code="${existing_version_with_code}+0"
    fi

    existing_version_android=$(echo $existing_version_with_code | awk -F '+' '{print $1}')
    existing_code_android=$(echo $existing_version_with_code | awk -F '+' '{print $2}')

    new_code_android=$existing_code_android
    let "new_code_android++"

    major=$(echo $existing_version_android | awk -F '.' '{print $1}')
    minor=$(echo $existing_version_android | awk -F '.' '{print $2}')
    patch=$(echo $existing_version_android | awk -F '.' '{print $3}')

    if [ "$1" = '1' ]; then
        let "major++"
        minor=0
        patch=0
    elif [ "$1" = '2' ]; then
        let "minor++"
        patch=0
    elif [ "$1" = '3' ]; then
        let "patch++"
    fi

    new_version_android=${major}.${minor}.${patch}+${new_code_android}

    sed "s/${existing_version_with_code}/${new_version_android}/g" pubspec.yaml > android_version
    cat android_version > pubspec.yaml
    rm android_version

    green='\033[0;32m'
    echo "${green}Android Version updated successfully!${clear}"
}

if [ "$input" = '' ]; then 
    error
    exit 1
fi

if [ "$input" -gt 0 ] && [ "$input" -lt 4 ]; then
    incrementAndroidVersion $input
    echo ''
    incrementIosVersion $input
    echo ''

    # Extract new Flutter version for branch name
    new_version=$(grep version: pubspec.yaml | awk -F 'version: ' '{print $2}' | awk -F '+' '{print $1}')
    branch_name="release/${new_version}"

    # Checkout new branch
    git checkout -b "$branch_name"

    # Commit & push
    git add pubspec.yaml ios/Runner.xcodeproj/project.pbxproj
    git commit -m "Release version $new_version"
    git push -u origin "$branch_name"

    echo -e "\033[0;32mChanges committed and pushed to new branch '$branch_name' successfully!${clear}"
else 
    error
    exit 1
fi
