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

# Resources that this plan creates or updates.
changed contains rc if {
	some rc in input.resource_changes
	some action in rc.change.actions
	action in {"create", "update"}
}

deny contains msg if {
	some rc in changed
	rc.type == "aws_launch_template"
	env := rc.change.after.tags_all.environment
	itype := rc.change.after.instance_type
	not itype in allowed_instance_types[env]
	allowed := concat(", ", sort(allowed_instance_types[env]))
	msg := sprintf("%s: %s is not allowed in %s (allowed: %s)", [rc.address, itype, env, allowed])
}

deny contains msg if {
	some rc in changed
	tags := rc.change.after.tags_all
	missing := required_tags - {key | some key, _ in tags}
	count(missing) > 0
	msg := sprintf("%s: missing cost tags: %s", [rc.address, concat(", ", sort(missing))])
}

deny contains msg if {
	some rc in changed
	rc.type == "aws_ebs_volume"
	rc.change.after.type == "gp2"
	msg := sprintf("%s: use gp3, which costs less per GB than gp2", [rc.address])
}

warn contains msg if {
	some rc in changed
	rc.type == "aws_db_instance"
	rc.change.after.multi_az == true
	rc.change.after.tags_all.environment != "prod"
	msg := sprintf("%s: Multi-AZ doubles the instance cost; is it needed outside prod?", [rc.address])
}
