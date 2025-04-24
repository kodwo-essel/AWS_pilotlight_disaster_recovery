output "global_accelerator_ips" {
  value = aws_globalaccelerator_accelerator.main.ip_sets[0].ip_addresses
}