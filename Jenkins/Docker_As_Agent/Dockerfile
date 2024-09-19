# Use a base image that has Java installed, since Jenkins needs Java to run.
FROM jenkins/inbound-agent:jdk11

# Install Docker CLI inside the agent container, so Jenkins can run Docker commands.
USER root

# Install Docker and other dependencies
RUN apt-get update && \
    apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    apt-get clean

# Give Jenkins user permission to use Docker
RUN usermod -aG docker jenkins

# Switch back to the Jenkins user
USER jenkins

# Set the working directory (Optional)
WORKDIR /home/jenkins/agent

# Default CMD is provided by the parent jenkins/inbound-agent image


COPY index.html /usr/share/nginx/html
