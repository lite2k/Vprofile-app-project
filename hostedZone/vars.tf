variable "Region" {
  type = string
  description = "Aws region used"
}
variable "dbPrivIP" {
  type = string
  description = "database Private ip address"
}
variable "mcPrivIP" {
  type = string
  description = "memcached Private ip address"
}
variable "rmqPrivIP" {
  type = string
  description = "rabbit mq private ip address"
}
