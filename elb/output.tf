output "elbSG-ID" {
    value = aws_security_group.ELBSG.id
    description = "elb security group id"
}
output "dnsName" {
  value = aws_lb.Vprofile-ELB.dns_name
  description = "loadbalancer dns name"
}
