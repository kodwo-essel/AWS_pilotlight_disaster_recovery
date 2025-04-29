output "alb_arn" {
  value = aws_lb.this.arn
}

output "alb_name" {
  value = aws_lb.this.name
}

output "alb_dns_name" {
  value = aws_lb.this.dns_name
}

output "frontend_target_group_arn" {
  value = aws_lb_target_group.this.arn
}

output "backend_target_group_arn" {
  value = aws_lb_target_group.alt.arn
}

output "alb_arn_suffix" {
  value = aws_lb.this.arn_suffix
}

output "frontend_tg_arn_suffix" {
  value = aws_lb_target_group.this.arn_suffix
}

output "backend_tg_arn_suffix" {
  value = aws_lb_target_group.alt.arn_suffix
}
