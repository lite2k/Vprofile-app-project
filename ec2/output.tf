output "dbIP" {
  value       = aws_instance.DB.private_ip
  description = "Private ip of databse instance"
}
output "mcIP" {
  value       = aws_instance.MC.private_ip
  description = "Private ip of memecached instance"
}
output "rmqIP" {
  value       = aws_instance.RMQ.private_ip
  description = "Private ip of rabbit mq instance"
}
output "mcIP" {
  value       = aws_instance.APP.public_ip
  description = "Public ip of tomcat app instance"
}
output "AppID" {
    value = aws_instance.APP.id
    description = "App instance id"
}
