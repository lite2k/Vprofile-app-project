# Vprofile-app-project
This Is a script to host an app on aws servers.
The script will attempt to create the following resources:
 1) 3 security groups.
 2) 1 Key pair.
 3) 4 ec2 instances
 4) 1 private hosted zone with 3 records
 5) 1 S3 bucket
 6) 1 IAM role with AmazonS3FullAccess policy
 7) 1 Instance profile
 8) 1 Target group
 9) 1 application loadbalancer with HTTP and HTTPS listener.
 10) 1 ami
 11) 1 launch configuration
 12) autoscaling group with avg cpu utilization policy and 505 threshold.
* * *
 # Dependecies
 You need the awscli v2 to be able to use the script.
