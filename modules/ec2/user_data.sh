#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# Installing Docker Compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

# Apply executable permissions to the docker-compose binary
sudo chmod +x /usr/local/bin/docker-compose

# Add /usr/local/bin to the PATH in .bashrc
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc

# Source .bashrc to update the current session
source ~/.bashrc

# Verify the installation
docker-compose --version