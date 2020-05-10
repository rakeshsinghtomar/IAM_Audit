#!/bin/bash
set -e
###
#
# List of IAM users and their attached policies in AWS for a quick audit.
# Note: Doesn't include inline policies.
#
# Requirements: aws-cli, jq
#
# Usage:
#   ./aws-iam-user-policies.sh
#   ./aws-iam-user-policies.sh --profile something
###

users=$(aws "$@" iam list-users | jq -r ".Users[].UserName")

if [ -z "${users}" ]; then
  printf "Your AWS account has no users."

  exit 1
fi
bold=$(tput bold)
normal=$(tput sgr0)

echo ""
echo ""
echo  "-------------------  Listing AWS IAM Users and Policies  ------------------"
echo ""
echo ""
printf "        %-50s  %s \n" ${bold}"Username"             "Policies"${normal}

for user in $users; do
  policies=$(aws "$@" iam list-attached-user-policies --user-name "$user" | jq -r '.AttachedPolicies | map(.PolicyName) | join(", ")')
  user_groups=$(aws "$@" iam list-groups-for-user --user-name "$user" | jq -r '.Groups[].GroupName')
  group_policies=

  for group in $user_groups; do
    group_policies+=$(aws "$@" iam list-attached-group-policies --group-name "$group" | jq -r '.AttachedPolicies | map(.PolicyName) | join(", ")')

    if [ -n "$group_policies" ]; then
      group_policies+=", "
    fi
  done

  if [ -n "$policies" ] && [ -n "$group_policies" ]; then
    policies+=" - "
  fi

  if [ -n "$group_policies" ]; then
    policies+="(g) ${group_policies%??}"
  fi

  printf "| %-50s | %s\n" "$user" "$policies"
done
echo ""
