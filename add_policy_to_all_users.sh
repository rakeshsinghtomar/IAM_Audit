#!/bin/bash

set -e

users=$(aws "$@" iam list-users | jq -r ".Users[].UserName")

if [ -z "${users}" ]; then
  printf "Your AWS account has no users. Woah! ¯\_(ツ)_/¯"

  exit 1
fi
echo ""
read -p "Please pass the new Policy ARN to add in all Users  --   " var
echo ""
echo "Adding above policy to all users "
echo ""

for usr in $users; do
	command_add=$(aws iam attach-user-policy --policy-arn ${var} --user-name ${usr}) 
${command_add}
done

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

  printf "| %-40s | %s\n" "$user" "$policies"
done
