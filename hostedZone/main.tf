resource "aws_route53_zone" "HZD" {
  name    = "vprofile.in"
  comment = "Private hosted zone"
  vpc {
    vpc_id     = var.defaultVPC
    vpc_region = var.Region
  }
}
resource "aws_route53_record" "db" {
  zone_id = aws_route53_zone.HZD.zone_id
  name    = "db.vprofile.in"
  type    = "A"
  ttl     = "300"
  records = var.dbPrivIP
}
resource "aws_route53_record" "mc" {
  zone_id = aws_route53_zone.HZD.zone_id
  name    = "db.vprofile.in"
  type    = "A"
  ttl     = "300"
  records = var.mcPrivIP
}
resource "aws_route53_record" "rmq" {
  zone_id = aws_route53_zone.HZD.zone_id
  name    = "db.vprofile.in"
  type    = "A"
  ttl     = "300"
  records = var.rmqPrivIP
}
