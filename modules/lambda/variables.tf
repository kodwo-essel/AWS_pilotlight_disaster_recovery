variable "function_name" {}
variable "image_uri" {}
variable "timeout" {
  default = 300
}
variable "memory_size" {
  default = 128
}
variable "environment_variables" {
  type = map(string)
  default = {}
}
