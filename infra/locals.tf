locals {
  # The tag schema. Keys are lowercase with hyphens; activate them as cost allocation tags.
  cost_tags = {
    team          = var.team
    service       = var.service
    environment   = var.environment
    "cost-center" = var.cost_center
    owner         = var.owner
    "managed-by"  = "terraform"
  }

  # Production capacity only where production needs it.
  sizes = {
    dev = {
      instance_type     = "t4g.small"
      min_size          = 0 # the office-hours schedule below sets the capacity
      max_size          = 2
      db_instance_class = "db.t4g.micro"
      db_storage_gb     = 20
      db_multi_az       = false
      db_backup_days    = 1
      office_hours_only = true
    }
    staging = {
      instance_type     = "t4g.medium"
      min_size          = 1
      max_size          = 2
      db_instance_class = "db.t4g.small"
      db_storage_gb     = 20
      db_multi_az       = false
      db_backup_days    = 3
      office_hours_only = false
    }
    prod = {
      instance_type     = "m8g.large"
      min_size          = 2
      max_size          = 6
      db_instance_class = "db.m8g.large"
      db_storage_gb     = 100
      db_multi_az       = true
      db_backup_days    = 14
      office_hours_only = false
    }
  }

  size          = local.sizes[var.environment]
  instance_type = coalesce(var.instance_type, local.size.instance_type)
  name          = "${var.service}-${var.environment}"
}
