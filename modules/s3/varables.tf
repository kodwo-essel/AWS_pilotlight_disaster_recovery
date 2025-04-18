variable "bucket_prefix" {
  description = "Prefix used for naming the source and destination buckets"
  type        = string
}

variable "replica_region" {
  description = "Secondary region for replication"
  type        = string
}
