#!/bin/bash
#
# This script is for listing the aws resource usage.
#
set -x


# list s3 buckets
echo "list s3 buckets"
aws s3 ls | awk -F" " '{print $3}'

# list EC2 Instances
echo "list ec2 instances"
aws ec2 describe-instances | jq '.Reservations[].Instances[].InstanceId'


# list lambda
echo "list lambda functions"
aws lambda list-functions | jq '.Functions[].FunctionName'


# list IAM users
echo "list IAM users"
aws iam list-users | jq '.Users[].UserName'
