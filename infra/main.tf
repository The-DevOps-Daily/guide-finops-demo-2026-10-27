resource "aws_launch_template" "app" {
  name_prefix   = "${local.name}-"
  image_id      = var.ami_id
  instance_type = local.instance_type

  metadata_options {
    http_tokens = "required"
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  # default_tags tag the launch template itself, not the instances and
  # volumes that the Auto Scaling group launches from it.
  tag_specifications {
    resource_type = "instance"
    tags          = local.cost_tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = local.cost_tags
  }
}

resource "aws_autoscaling_group" "app" {
  name                = local.name
  vpc_zone_identifier = var.subnet_ids
  min_size            = local.size.min_size
  max_size            = local.size.max_size

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # The provider's default_tags skip aws_autoscaling_group, so tag it here.
  dynamic "tag" {
    for_each = local.cost_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  lifecycle {
    # Scaling policies and schedules change the desired capacity.
    ignore_changes = [desired_capacity]
  }
}

# Development runs on weekdays from 08:00 to 19:00 New York time.
resource "aws_autoscaling_schedule" "office_hours_start" {
  count = local.size.office_hours_only ? 1 : 0

  autoscaling_group_name = aws_autoscaling_group.app.name
  scheduled_action_name  = "office-hours-start"
  recurrence             = "0 8 * * MON-FRI"
  time_zone              = "America/New_York"
  min_size               = -1
  max_size               = -1
  desired_capacity       = 1
}

resource "aws_autoscaling_schedule" "office_hours_stop" {
  count = local.size.office_hours_only ? 1 : 0

  autoscaling_group_name = aws_autoscaling_group.app.name
  scheduled_action_name  = "office-hours-stop"
  recurrence             = "0 19 * * MON-FRI"
  time_zone              = "America/New_York"
  min_size               = -1
  max_size               = -1
  desired_capacity       = 0
}

resource "aws_db_instance" "app" {
  identifier                  = local.name
  engine                      = "postgres"
  engine_version              = "18"
  instance_class              = local.size.db_instance_class
  allocated_storage           = local.size.db_storage_gb
  storage_type                = "gp3"
  storage_encrypted           = true
  multi_az                    = local.size.db_multi_az
  backup_retention_period     = local.size.db_backup_days
  db_name                     = replace(var.service, "-", "_")
  username                    = "app"
  manage_master_user_password = true
  db_subnet_group_name        = var.db_subnet_group_name
  deletion_protection         = var.environment == "prod"
  skip_final_snapshot         = var.environment != "prod"
  final_snapshot_identifier   = var.environment == "prod" ? "${local.name}-final" : null
}
