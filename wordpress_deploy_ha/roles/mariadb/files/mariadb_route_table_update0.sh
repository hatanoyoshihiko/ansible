#!/bin/bash

VIP=10.0.0.40
ROUTE_TABLE_ID=rtb-ce7366b3
INSTANCE_ID=`curl -s 169.254.169.254/latest/meta-data/instance-id`

export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_DEFAULT_REGION=

aws --region us-east-1 ec2 delete-route --destination-cidr-block $VIP/32 --route-table-id $ROUTE_TABLE_ID
aws --region us-east-1 ec2 create-route --destination-cidr-block $VIP/32 --route-table-id $ROUTE_TABLE_ID --instance-id $INSTANCE_ID
