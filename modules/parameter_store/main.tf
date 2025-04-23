terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
    }
  }
}

# modules/parameter-store/main.tf
resource "aws_ssm_parameter" "parameter" {
  for_each = { for param in var.parameters : param.name => param }

  name        = each.value.name
  type        = each.value.type
  value       = each.value.value
  description = lookup(each.value, "description", null)
  key_id      = each.value.type == "SecureString" ? lookup(each.value, "key_id", null) : null

  tags = merge(
    var.default_tags,
    lookup(each.value, "tags", {})
  )
}