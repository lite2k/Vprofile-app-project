#!/usr/bin/bash

cd ~

MYIP=$(curl https://checkip.amazonaws.com)
MYIP="$MYIP/32"
echo -e "Current ip address is $MYIP\n"

echo "Looking for existing Sec Group Elb-SG"
ELBSG=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='Elb-SG'].GroupId" --output text)
if [[ -z "$ELBSG" ]]; then
        echo "Security Group not found, Creating......."
        ELBSG=$(aws ec2 create-security-group --group-name Elb-SG \
                                              --description "security group for Load balancer" \
                                              --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Elb-SG},{Key=Project,Value=Vprofile}]" \
                                              --query "GroupId" \
                                              --output text)

        echo -e "Created new sec group Elb-SG\nAdding rules to sec Group....."
        aws ec2 authorize-security-group-ingress --group-id "$ELBSG" \
                                                 --ip-permissions FromPort=80,ToPort=80,IpProtocol=tcp,IpRanges="[{CidrIp=0.0.0.0/0,Description='Allows Http trafic from all ips'}]",Ipv6Ranges="[{CidrIpv6=::/0,Description='Allows Http trafic from all ips (v6)'}]" FromPort=443,ToPort=443,IpProtocol=tcp,IpRanges="[{CidrIp=0.0.0.0/0,Description='Allows Https trafic from all ips'}]",Ipv6Ranges="[{CidrIpv6=::/0,Description='Allows Https trafic from all ips (v6)'}]" \
                                                 --query "SecurityGroupRules[*].{Proto:IpProtocol, Port:FromPort, Ipv4:CidrIpv4, Ipv6:CidrIpv6,Desc:Description}" \
                                                 --output table 
else
        echo "Found a security group with name Elb-SG, ID=$ELBSG"
fi

echo "Looking for existing Sec Group App-SG"
APPSG=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='App-SG'].GroupId" --output text)
if [[ -z "$APPSG" ]]; then
        APPSG=$(aws ec2 create-security-group --group-name App-SG \
                                              --description "security group for Tomcat" \
                                              --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=App-SG},{Key=Project,Value=Vprofile}]" \
                                              --query "GroupId" \
                                              --output text)

        echo "Created new sec group App-SG\n Adding rules to sec Group....."
        aws ec2 authorize-security-group-ingress --group-id "$APPSG" \
                                                 --ip-permissions FromPort=22,ToPort=22,IpProtocol=tcp,IpRanges="[{CidrIp=$MYIP,Description='Allows ssh trafic from my ip'}]" \
                                                 --query "SecurityGroupRules[*].{Proto:IpProtocol, Port:FromPort, Ipv4:CidrIpv4, Ipv6:CidrIpv6,Desc:Description}" \
                                                 --output table 

        aws ec2 authorize-security-group-ingress --group-id "$APPSG" \
                                                 --protocol tcp \
                                                 --port 8080 \
                                                 --source-group "$ELBSG" \
                                                 --query "SecurityGroupRules[*].{Proto:IpProtocol, Port:FromPort, Ipv4:CidrIpv4, Ipv6:CidrIpv6,Desc:Description}" \
                                                 --output table 
else 
        echo "Found a security group with name App-SG, ID=$APPSG"
fi

echo "Looking for existing Sec Group Backend-SG"
BCKSG=$(aws ec2 describe-security-groups --query "SecurityGroups[?GroupName=='Backend-SG'].GroupId" --output text)

if [[ -z "$BCKSG" ]]; then
        BCKSG=$(aws ec2 create-security-group --group-name Backend-SG \
                                              --description "security group for Backend services(memcache,rabbitmq,mysql database)" \
                                              --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=Backend-SG},{Key=Project,Value=Vprofile}]" \
                                              --query "GroupId" \
                                              --output text)

        echo "Created new sec group Backend-SG\n Adding rules to sec Group....."

        aws ec2 authorize-security-group-ingress --group-id "$BCKSG" \
                                                 --ip-permissions FromPort=22,ToPort=22,IpProtocol=tcp,IpRanges="[{CidrIp=$MYIP,Description='Allows shh trafic from myip'}]" \
                                                 --query "SecurityGroupRules[*].{Proto:IpProtocol, Port:FromPort, Ipv4:CidrIpv4, Ipv6:CidrIpv6,Desc:Description}" \
                                                 --output table

        aws ec2 authorize-security-group-ingress --group-id "$BCKSG" \
                                                 --protocol tcp \
                                                 --port 3306 \
                                                 --source-group "$APPSG" \
                                                 --query "SecurityGroupRules[*].{Proto:IpProtocol, Port:FromPort, Ipv4:CidrIpv4, Ipv6:CidrIpv6,Desc:Description}" \
                                                 --output table 

        aws ec2 authorize-security-group-ingress --group-id "$BCKSG" \
                                                 --protocol tcp \
                                                 --port 11211 \
                                                 --source-group "$APPSG" \
                                                 --query "SecurityGroupRules[*].{Proto:IpProtocol, Port:FromPort, Ipv4:CidrIpv4, Ipv6:CidrIpv6,Desc:Description}" \
                                                 --output table 

        aws ec2 authorize-security-group-ingress --group-id "$BCKSG" \
                                                 --protocol tcp \
                                                 --port 5672 \
                                                 --source-group "$APPSG" \
                                                 --query "SecurityGroupRules[*].{Proto:IpProtocol, Port:FromPort, Ipv4:CidrIpv4, Ipv6:CidrIpv6,Desc:Description}" \
                                                 --output table 
else 
        echo "Found a security group with name App-SG, ID=$BCKSG"
fi         

echo -e "Security Groups Ready.\n"

echo "Looking for existing keys"
KEYID=$(aws ec2 describe-key-pairs --query "KeyPairs[?KeyName=='project-key'].KeyPairId" --output text)
if [[ -z "$KEYID" ]]; then
        echo "Creating Key pair....."
        aws ec2 create-key-pair --key-name "project-key" --key-format pem --query "KeyMaterial" --output text > ~/Documents/projectkey.pem

        echo "Setting key file permissions to 600...."
        chmod 600 ~/Documents/projectkey.pem
else
        echo 'Found Key with name [project-key]'
fi

echo -e "Key pair Ready\n"
TIMESTAMP=$(date +%D@%R:%S)
REGION="us-east-1"

echo "creating instances"
DBIP=$(aws ec2 describe-instances --filters Name=tag:Name,Values=db01 Name=tag:Project,Values=v-profile --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
if [[ -z "$DBIP" ]]; then

        echo "Instance db01 not found, creating........"

        #Centos7 machine for database
        DBIP=$(aws ec2 run-instances --image-id ami-002070d43b0a4f171 \
                                     --instance-type t2.micro \
                                     --key-name project-key \
                                     --security-group-ids "$BCKSG" \
                                     --user-data file://~/Repos/vprofile-project/userdata/mysql.sh \
                                     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=db01},{Key=Project,Value=v-profile}]' \
                                     --query "Instances[*].PrivateIpAddress" \
                                     --output text)
else 
        echo "Found db01"
fi

MCIP=$(aws ec2 describe-instances --filters Name=tag:Name,Values=mc01 Name=tag:Project,Values=v-profile --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
if [[ -z "$MCIP" ]]; then
        echo "Instance mc01 not found, creating........"

        #Centos7 machine for memcached
        MCIP=$(aws ec2 run-instances --image-id ami-002070d43b0a4f171 \
                                     --instance-type t2.micro \
                                     --key-name project-key \
                                     --security-group-ids "$BCKSG" \
                                     --user-data file://~/Repos/vprofile-project/userdata/memcache.sh \
                                     --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=mc01},{Key=Project,Value=v-profile}]' \
                                     --query "Instances[*].PrivateIpAddress" \
                                     --output text)
else 
        echo "Found mc01"
fi

RMQIP=$(aws ec2 describe-instances --filters Name=tag:Name,Values=rmq01 Name=tag:Project,Values=v-profile --query "Reservations[*].Instances[*].PrivateIpAddress" --output text)
if [[ -z "$RMQIP" ]]; then
        echo "Instance rmq01 not found, creating........"

        #Centos7 machine for rabbitmq
        RMQIP=$(aws ec2 run-instances --image-id ami-002070d43b0a4f171 \
                                      --instance-type t2.micro \
                                      --key-name project-key \
                                      --security-group-ids "$BCKSG" \
                                      --user-data file://~/Repos/vprofile-project/userdata/rabbitmq.sh \
                                      --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rmq01},{Key=Project,Value=v-profile}]' \
                                      --query "Instances[*].PrivateIpAddress" \
                                      --output text)
else 
        echo "Found rmq01"
fi

APP_PUBLIC_IP=$(aws ec2 describe-instances --filters Name=tag:Name,Values=app01 Name=tag:Project,Values=v-profile --query "Reservations[*].Instances[*].PublicIpAddress" --output text)
if [[ -z "$APP_PUBLIC_IP" ]]; then
        echo "Instance app01 not found, creating........"

        #Ubuntu 18.04 machine for tomcat server
        APPID=$(aws ec2 run-instances --image-id ami-0ee23bfc74a881de5 \
                                      --instance-type t2.micro \
                                      --key-name project-key \
                                      --security-group-ids "$APPSG" \
                                      --user-data file://~/Repos/vprofile-project/userdata/tomcat_ubuntu.sh \
                                      --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=app01},{Key=Project,Value=v-profile}]' \
                                      --query "Instances[*].InstanceId" \
                                      --output text)
        echo "Waiting for app01 to come online"
        sleep 30
        STATUS=$(aws ec2 describe-instances --filters "Name=instance-id,Values=$APPID" --query "Reservations[*].Instances[*].State.Name" --output text)
        while [[ "$STATUS" != "running" ]]; 
        do
                echo -e "Instance is still $STATUS \n"
                echo -e "starting delay..."
                sleep 30
                STATUS=$(aws ec2 describe-instances --filters "Name=instance-id,Values=$APPID" --query "Reservations[*].Instances[*].State.Name" --output text)
        done

        APP_PUBLIC_IP=$(aws ec2 describe-instances --filters "Name=instance-id,Values=$APPID" \
                                                   --query "Reservations[*].Instances[*].PublicIpAddress"\
                                                   --output text)
else 
        echo "Found app01"
        APPID=$(aws ec2 describe-instances --filters Name=tag:Name,Values=app01 Name=tag:Project,Values=v-profile Name=instance-state-name,Values=running --query "Reservations[*].Instances[*].InstanceId" --output text)
fi
echo -e "\n"
echo "APPIP = $APP_PUBLIC_IP"
echo "RMQIP = $RMQIP"
echo "MCIP  = $MCIP "
echo "DBIP  = $DBIP "
echo -e "\n"

#get default vpc id
DEFAULT_VPC=$(aws ec2 describe-vpcs --filter "Name=is-default,Values=true" --query "Vpcs[*].VpcId" --output text)

echo "Looking for an existing hosted zone"
HZID=$(aws route53 list-hosted-zones-by-name --dns-name vprofile.in --query "HostedZones[*].Id" --output text)

if [[ -z "$HZID" ]]; then
        echo "creating hosted zone"
        # create a route53 private hosted zone
        HZID=$(aws route53 create-hosted-zone --name vprofile.in \
                                              --vpc VPCRegion="$REGION",VPCId="$DEFAULT_VPC" \
                                              --caller-reference "$TIMESTAMP" \
                                              --hosted-zone-config Comment="Private hosted zone for vprofile project",PrivateZone=true \
                                              --query "HostedZone.Id" \
                                              --output text)
        echo "Created hosted zone with ID = $HZID"
else
        echo "Found Hosted zone With ID=$HZID"
fi

# create json file with record data
cat << EOF > ~/Scripts/Bash/records.json
{
             "Comment": "CREATE simple records for db01,rmq01,mc01",
              "Changes": [ {
                          "Action": "UPSERT",
                          "ResourceRecordSet": {
                                 "Name": "db01.vprofile.in",
                                 "Type": "A",
                                 "TTL": 300,
                                 "ResourceRecords": [{"Value": "$DBIP"}]
                         }},
                         {
                         "Action": "UPSERT",
                         "ResourceRecordSet": {
                              "Name": "mc01.vprofile.in",
                              "Type": "A",
                              "TTL": 300,
                              "ResourceRecords": [{"Value": "$MCIP"}]
                         }},
                         {
                         "Action": "UPSERT",
                         "ResourceRecordSet": {
                              "Name": "rmq01.vprofile.in",
                              "Type": "A",
                              "TTL": 300,
                              "ResourceRecords":[{"Value": "$RMQIP"}]
                        }}
]
}
EOF

echo "adding records to route53......"
# add records to route53 hosted zone
aws route53 change-resource-record-sets --hosted-zone-id "$HZID" --change-batch file://~/Scripts/Bash/records.json
echo -e "\n"

echo "building app artifact......."
build app artifact 
cd ~/Repos/vprofile-project
mvn install

echo -e "\n"

BUCKET_NAME=$(aws s3api list-buckets --query "Buckets[?Name=='vprofile-artifact-storage-lite'].Name" --output text)
if [[ -z "$BUCKET_NAME" ]]; then 
        echo "Bucket not found Creating........"
        aws s3 mb s3://vprofile-artifact-storage-lite --region us-east-1
else
        echo "S3 bucket found with name: $BUCKET_NAME"
fi

aws s3 cp ./target/vprofile-v2.war s3://vprofile-artifact-storage-lite
echo -e "\n"

# Check for existing role
ROLE=$(aws iam list-roles --query "Roles[?RoleName=='s3AccessRole'].RoleName" --output text)
if [[ -z "$ROLE" ]]; then 
        echo "creating IAM role......................"
        aws iam create-role --role-name s3AccessRole --assume-role-policy-document file://~/Scripts/Bash/trustpolicy.json
else
        echo "Iam Role Found, Checking policies......"
fi 

POLICY=$(aws iam list-attached-role-policies --role-name s3AccessRole --query "AttachedPolicies[?PolicyName=='AmazonS3FullAccess'].PolicyName" --output text)
if [[ "$POLICY" != "AmazonS3FullAccess" ]]; then
        echo "attaching S3 Full Access policy to role.............."
        aws iam attach-role-policy --role-name s3AccessRole --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
else
        echo "Found S3 full access policy attached, continuing.........."
fi

INST_PROF_ARN=$(aws iam list-instance-profiles --query "InstanceProfiles[?InstanceProfileName=='s3AccessInstanceProfile'].Arn" --output text)
ATCH_ROLE_NAME=$(aws iam list-instance-profiles --query "InstanceProfiles[?InstanceProfileName=='s3AccessInstanceProfile'].Roles[*].RoleName" --output text)

if [[ -z "$INST_PROF_ARN" ]]; then
        # Create instance profile 
        INST_PROF_ARN=$(aws iam create-instance-profile --instance-profile-name s3AccessInstanceProfile --query "InstanceProfile.Arn" --output text)
        echo -e "INST_PROF_ARN = $INST_PROF_ARN\n"
else
        echo "Found Instance Profile with Name: s3AccessInstanceProfile, ARN: $INST_PROF_ARN"
fi

# Attach role to instance profile 
if [[ -z "$ATCH_ROLE_NAME" ]]; then
        echo "Attaching role to instance profile" 
        aws iam add-role-to-instance-profile --role-name s3AccessRole --instance-profile-name s3AccessInstanceProfile
else
        echo "Role Already attached to instance profile"
fi

echo "attaching ec2 to profile.................."
ASOC_DATA=$(aws ec2 describe-iam-instance-profile-associations --query "IamInstanceProfileAssociations[?InstanceId=='"$APPID"'].IamInstanceProfile.[Arn, Id]" --output text)
ASOC_ARN=$(echo "$ASOC_DATA" | awk -F'[[:space:]]+' '{print $1}')
ASOC_ID=$(echo "$ASOC_DATA" | awk -F'[[:space:]]+' '{print $2}')

if [[ -z "$ASOC_ARN" ]]; then
        aws ec2 associate-iam-instance-profile --instance-id "$APPID" --iam-instance-profile Name=s3AccessInstanceProfile,Arn="$INST_PROF_ARN"
elif [[ "$ASOC_ARN" != "$INST_PROF_ARN" ]]; then
        aws ec2 disassociate-iam-instance-profile --association-id "$ASOC_ID"
        aws ec2 associate-iam-instance-profile --instance-id "$APPID" --iam-instance-profile Name=s3AccessInstanceProfile,Arn="$INST_PROF_ARN"
else
        echo "Instance profile is already associated with app01"
fi

echo -e "\n"

echo "excuting commands over ssh............"
#Excute commands over ssh to download artifact from s3 bucket, place it in correct directory for tomcat to recognize.
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ~/Documents/projectkey.pem ubuntu@"$APP_PUBLIC_IP" \
           "sudo systemctl stop tomcat8;sudo rm -rf /var/lib/tomcat8/webapps/ROOT;aws s3 cp s3://vprofile-artifact-storage-lite/vprofile-v2.war /tmp/vprofile-v2.war;sudo cp /tmp/vprofile-v2.war /var/lib/tomcat8/webapps/ROOT.war;sudo systemctl start tomcat8"

echo -e "\n"

echo "creating target group............"
TARGET_GROUP_ARN=$(aws elbv2 describe-target-groups --query "TargetGroups[?TargetGroupName=='vprofile-app-TG'].TargetGroupArn" --output text)
if [[ -z "$TARGET_GROUP_ARN" ]]; then

        # create target group 
        TARGET_GROUP_ARN=$(aws elbv2 create-target-group --name vprofile-app-TG \
                                                         --protocol HTTP \
                                                         --port 8080 \
                                                         --vpc-id "$DEFAULT_VPC" \
                                                         --health-check-protocol HTTP \
                                                         --health-check-path "/login" \
                                                         --health-check-port 8080 \
                                                         --healthy-threshold-count 3 \
                                                         --target-type instance \
                                                         --query "TargetGroups[*].TargetGroupArn" \
                                                         --output text)
else
        echo "Found Target Group"
fi

echo "Modifing target group attributes"
# Add stickness to target group
aws elbv2 modify-target-group-attributes --target-group-arn "$TARGET_GROUP_ARN" \
                                         --attributes Key=stickiness.enabled,Value=true Key=stickiness.lb_cookie.duration_seconds,Value=3600 \
                                         --output table

echo "registering targets to target group"
# Register app01 instance to target group.
aws elbv2 register-targets --target-group-arn "$TARGET_GROUP_ARN" \
                           --targets Id="$APPID"
echo -e "\n"

ELB_DATA=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?LoadBalancerName=='vprofile-elb'].[LoadBalancerArn, DNSName]" --output text)
ELB_ARN=$(echo "$ELB_DATA" | awk -F'[[:space:]]+' '{print $1}')
DNSNAME=$(echo "$ELB_DATA" | awk -F'[[:space:]]+' '{print $2}')

if [[ -z "$ELB_ARN" ]]; then
        echo "getting default subnets"

        # Get subnet ids of us-east-1 regions for load balancer
        EAST1A=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=us-east-1a" --query "Subnets[*].SubnetId" --output text)
        EAST1B=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=us-east-1b" --query "Subnets[*].SubnetId" --output text)
        EAST1C=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=us-east-1c" --query "Subnets[*].SubnetId" --output text)
        EAST1D=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=us-east-1d" --query "Subnets[*].SubnetId" --output text)
        EAST1E=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=us-east-1e" --query "Subnets[*].SubnetId" --output text)
        EAST1F=$(aws ec2 describe-subnets --filters "Name=availability-zone,Values=us-east-1f" --query "Subnets[*].SubnetId" --output text)

        echo "creating load balancer"
        # Create internet-facing application load balancer 
        ELB_ARN=$(aws elbv2 create-load-balancer --name vprofile-elb \
                                                 --subnets "$EAST1A" "$EAST1B" "$EAST1C" "$EAST1D" "$EAST1E" "$EAST1F"\
                                                 --scheme internet-facing \
                                                 --security-groups "$ELBSG" \
                                                 --type application \
                                                 --query "LoadBalancers[*].LoadBalancerArn" \
                                                 --output text)
else
        echo "Found ELB"
fi

echo "Getting domain certificate............."
# retrive domain certificate 
CERT=$(aws acm list-certificates --query "CertificateSummaryList[*].CertificateArn" --output text)

echo "Creating listeners"
aws elbv2 create-listener --load-balancer-arn "$ELB_ARN"\
                          --protocol HTTP \
                          --port 80 \
                          --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN"

aws elbv2 create-listener --load-balancer-arn "$ELB_ARN"\
                          --protocol HTTPS \
                          --port 443 \
                          --certificates CertificateArn="$CERT" \
                          --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN"
echo -e "\n"

if [[ -z "$DNSNAME" ]]; then

        echo "geting load balancer dns name"

        # get load balancer dns name
        DNSNAME=$(aws elbv2 describe-load-balancers --load-balancer-arns "$ELB_ARN" --query "LoadBalancers[*].DNSName" --output text)
fi

echo "dnsname is ($DNSNAME)"
echo -e "\n"

IMAGEID=$(aws ec2 describe-images --query "Images[?Name=='vprofile-app-image'].ImageId" --output text)
if [[ -z "$IMAGEID" ]]; then

        echo "cretaing image.............."
        # create Ami from app01 for use in autoscaling group
        IMAGEID=$(aws ec2 create-image --name vprofile-app-image --instance-id "$APPID" --output text)
else
        echo "Found Ami"
fi

echo "creating launch config.........."


LAUNCH_CONFIG=$(aws autoscaling describe-launch-configurations --query "LaunchConfigurations[?LaunchConfigurationName=='vprofile-app-LC'].LaunchConfigurationName" --output text)

if [[ -z "$LAUNCH_CONFIG" ]]; then
        #create launch config using app01 ami
        aws autoscaling create-launch-configuration --launch-configuration-name vprofile-app-LC \
                                                    --image-id "$IMAGEID" \
                                                    --key-name project-key \
                                                    --security-groups "$APPSG" \
                                                    --instance-type t2.micro \
                                                    --instance-monitoring Enabled=true \
                                                    --iam-instance-profile "$INST_PROF_ARN"
else
        echo "Found Launch Configuaration"
fi


ASG=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?AutoScalingGroupName=='vprofile-app-ASG'].AutoScalingGroupName" --output text)
if [[ -z "$ASG" ]]; then
        echo "creating autoscaling group"

        # create autoscaling group 
        aws autoscaling create-auto-scaling-group --auto-scaling-group-name vprofile-app-ASG \
                                                  --launch-configuration-name vprofile-app-LC \
                                                  --desired-capacity 1 \
                                                  --min-size 1 \
                                                  --max-size 2 \
                                                  --availability-zones us-east-1a us-east-1b us-east-1c us-east-1d us-east-1e us-east-1f \
                                                  --target-group-arns "$TARGET_GROUP_ARN" \
                                                  --health-check-type ELB \
                                                  --no-new-instances-protected-from-scale-in \
                                                  --tags "ResourceId=vprofile-app-ASG,ResourceType=auto-scaling-group,Key=Name,Value=vprofile-app,PropagateAtLaunch=true" "ResourceId=vprofile-app-ASG,ResourceType=auto-scaling-group,Key=Project,Value=vprofile,PropagateAtLaunch=true"
else
        echo "Found ASG"
fi
cat << EOF > ~/Scripts/Bash/tracking_policiy_config.json
{
  "TargetValue": 50.0,
  "PredefinedMetricSpecification": 
  {
    "PredefinedMetricType": "ASGAverageCPUUtilization"
  }
}
EOF

echo "adding scaling policy to asg"

# Add scaling policy to auto scaling group
aws autoscaling put-scaling-policy --policy-name cpu50-target-scaling-policy \
                                   --auto-scaling-group-name vprofile-app-ASG \
                                   --policy-type TargetTrackingScaling \
                                   --target-tracking-configuration file://~/Scripts/Bash/tracking_policiy_config.json
