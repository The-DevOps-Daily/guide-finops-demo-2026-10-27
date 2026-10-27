"""Creates a few test resources in a local moto server (not real AWS) for the dry run."""
import boto3

ec2 = boto3.client("ec2", region_name="us-east-1")
tags = [{"Key": "team", "Value": "payments"}, {"Key": "service", "Value": "checkout"}]

# Two volumes left behind by deleted instances.
for size in (20, 100):
    ec2.create_volume(
        AvailabilityZone="us-east-1a",
        Size=size,
        VolumeType="gp3",
        TagSpecifications=[{"ResourceType": "volume", "Tags": tags}],
    )

# An Elastic IP that nothing uses.
ec2.allocate_address(Domain="vpc")

# A running instance without an owner tag (its root volume is attached).
image = ec2.describe_images(Owners=["amazon"])["Images"][0]["ImageId"]
ec2.run_instances(
    ImageId=image,
    InstanceType="t4g.small",
    MinCount=1,
    MaxCount=1,
    TagSpecifications=[{"ResourceType": "instance", "Tags": tags}],
)
