package main

import rego.v1

# Instance types each environment may use. A bigger size is a policy change,
# reviewed like any other code change.
allowed_instance_types := {
	"dev": {"t4g.small", "t4g.medium"},
	"staging": {"t4g.medium", "m8g.large"},
	"prod": {"m8g.large", "m8g.xlarge", "m8g.2xlarge"},
}

required_tags := {"team", "service", "environment", "cost-center", "owner"}

# The environment comes from the plan's input variable, not from a tag that
# a resource could override.
environment := input.variables.environment.value

deny contains "the plan has no environment variable" if {
	not input.variables.environment.value
}

deny contains msg if {
	not allowed_instance_types[environment]
	msg := sprintf("environment %q has no list of allowed instance types", [environment])
}

# Resources that this plan creates or updates.
changed contains rc if {
	some rc in input.resource_changes
	some action in rc.change.actions
	action in {"create", "update"}
}

# Every set of tags that ends up on billed resources: the tags of each
# resource, the tags a launch template gives to the instances and volumes
# it launches, and the tags of an Auto Scaling group.
tag_sets contains [rc.address, rc.change.after.tags_all] if {
	some rc in changed
	is_object(rc.change.after.tags_all)
}

tag_sets contains [sprintf("%s (%s)", [rc.address, spec.resource_type]), spec.tags] if {
	some rc in changed
	rc.type == "aws_launch_template"
	some spec in rc.change.after.tag_specifications
}

tag_sets contains [rc.address, {t.key: t.value | some t in rc.change.after.tag}] if {
	some rc in changed
	rc.type == "aws_autoscaling_group"
}

deny contains msg if {
	some [address, tags] in tag_sets
	tags.environment != environment
	msg := sprintf("%s: environment tag %q does not match the environment %q", [address, tags.environment, environment])
}

deny contains msg if {
	some [address, tags] in tag_sets
	present := {key | some key, value in tags; trim_space(value) != ""}
	missing := required_tags - present
	count(missing) > 0
	msg := sprintf("%s: missing cost tags: %s", [address, concat(", ", sort(missing))])
}

deny contains msg if {
	some rc in changed
	rc.type == "aws_launch_template"
	tagged := {spec.resource_type | some spec in rc.change.after.tag_specifications}
	missing := {"instance", "volume"} - tagged
	count(missing) > 0
	msg := sprintf("%s: no tag_specifications for: %s", [rc.address, concat(", ", sort(missing))])
}

deny contains msg if {
	some rc in changed
	rc.type == "aws_launch_template"
	itype := rc.change.after.instance_type
	not itype in allowed_instance_types[environment]
	allowed := concat(", ", sort(allowed_instance_types[environment]))
	msg := sprintf("%s: %s is not allowed in %s (allowed: %s)", [rc.address, itype, environment, allowed])
}

# gp3 costs less per GB than gp2 for EBS volumes.
deny contains msg if {
	some rc in changed
	rc.type == "aws_ebs_volume"
	rc.change.after.type == "gp2"
	msg := sprintf("%s: use gp3 instead of gp2", [rc.address])
}

deny contains msg if {
	some rc in changed
	rc.type == "aws_launch_template"
	some mapping in rc.change.after.block_device_mappings
	some ebs in mapping.ebs
	ebs.volume_type == "gp2"
	msg := sprintf("%s: %s uses gp2; use gp3 instead", [rc.address, mapping.device_name])
}

warn contains msg if {
	some rc in changed
	rc.type == "aws_db_instance"
	rc.change.after.multi_az == true
	environment != "prod"
	msg := sprintf("%s: Multi-AZ doubles the instance cost; is it needed outside prod?", [rc.address])
}
