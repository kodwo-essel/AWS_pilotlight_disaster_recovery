output "alb_arn_suffix" {
  value = module.primary_alb.alb_arn_suffix
}

output "frontend_tg_arn_suffix" {
  value = module.primary_alb.frontend_tg_arn_suffix
}

output "backend_tg_arn_suffix" {
  value = module.primary_alb.backend_tg_arn_suffix
}

