#!/bin/bash
set -euxo pipefail
touch /var/log/startup.log
chmod 664 /var/log/startup.log
echo "* Starting provisioning" >> /var/log/startup.log 2>&1
echo "* $(date)" >> /var/log/startup.log 2>&1
# Update YUM
yum -y update >> /var/log/startup.log 2>&1
# Install ECS
amazon-linux-extras disable docker >> /var/log/startup.log 2>&1
amazon-linux-extras install -y ecs >> /var/log/startup.log 2>&1
# Update ECS config
mkdir -p /etc/ecs
echo 'ECS_CLUSTER=${ecs_cluster}' >> /etc/ecs/ecs.config
echo 'ECS_DISABLE_PRIVILEGED=true' >> /etc/ecs/ecs.config
echo 'ECS_CONTAINER_INSTANCE_TAGS=${jsonencode(tags)}' >> /etc/ecs/ecs.config
# Update shell
echo "export AWS_DEFAULT_REGION=${region}" >> /home/ec2-user/.bash_profile
# Starting ECS Service
systemctl enable --now --no-block ecs.service >> /var/log/startup.log 2>&1
echo "Done" >> /var/log/startup.log 2>&1
