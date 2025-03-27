#!/bin/bash

# Script that pulls a the DependencyCheck Docker Image from the Docker Registry server-chino-kali-linux-docker-registry and creates the container for running DependencyCheck

# Exits immediately if a command exits with a non-zero status
set -e 

# Defines the variables
DC_TAG_NAME="srv-kali-app01.telecom.arg.telecom.com.ar:8443/dependency-check-sca"              # DependencyCheck Docker Image name
DC_TAG_OS="ubuntu"                                                                             # Base OS used for the DependencyCheck Docker Image
REGISTRY_NAME="server-chino-kali-linux-docker-registry"                                        # Docker Registry name used to pull the Docker Images needed
DC_CONTAINER_NAME="dependency-check-sca"						       # DependencyCheck Docker Container name 

# Function to check the success of the last executed command
# Takes an error message as an argument and exits the script if the command failed
check_success() {
    local exit_code=$1
    local message=$2
    if [ $exit_code -ne 0 ]; then
        echo -e "\e[31mError: $message\e[0m"                                                   # Prints the error message in red
        exit $exit_code                         					       # Exits the script with the captured failure status
    fi
}

# Pulls the Docker Image for DependencyCheck from the Docker Registry server-chino-kali-linux-docker-registry
echo "Pulling the Docker Image '$DC_TAG_NAME' from the '$REGISTRY_NAME' Docker Registry at $(date)..."

docker pull $DC_TAG_NAME:$DC_TAG_OS

dc_docker_image_pull_from_registry_status=$?                                                   # Captures the exit code immediately
check_success $dc_docker_image_pull_from_registry_status "Failed to pull $TAG_NAME Docker Image from the $REGISTRY_NAME Docker Registry."

echo ""

# Lists the Docker Images and filter by the newly pulled Image for DependencyCheck
docker images | grep "$DC_TAG_NAME"

echo ""

dc_image_list_status=$?                                                                        # Captures the exit code immediately
check_success $dc_image_list_status "Failed to find the $DC_TAG_NAME Docker image." 
echo -e "\e[33mDocker Image $DC_TAG_NAME has been pulled successfully from the Docker Registry $REGISTRY_NAME!\e[0m"

echo ""

# Runs a Docker container using the newly pulled Docker Image for DependencyCheck
echo "Running the Docker Container with the recently pulled Docker Image '$DC_TAG_NAME' for DependencyCheck at $(date)..."

echo "" 

docker run -d --name "$DC_CONTAINER_NAME" "$DC_TAG_NAME:$DC_TAG_OS"
dc_docker_container_run_status=$?                                                              # Captures the exit code immediately
check_success $dc_docker_container_run_status "Failed to run $DC_TAG_NAME:$DC_TAG_OS Docker container."

echo ""

# Displays the running Docker Container's ID for confirmation of DependencyCheck Docker container creation
docker ps -q --filter "name=$DC_CONTAINER_NAME"

echo ""

docker_container_ps_status=$?                                                                  # Captures the exit code immediately
check_success $docker_container_ps_status "Failed to confirm the running status of the '$DC_CONTAINER_NAME' Docker container."
echo -e "\e[33mDocker Container '$DC_CONTAINER_NAME' is up and running!\e[0m"

echo ""

# Prints a success message
echo -e "\e[32mExecution completed successfully!\e[0m"

echo ""

# Enters the Docker container cli as root user
echo -e "\e[33mEntering the DependencyCheck Docker container cli as root user\e[0m"

echo ""

DC_DOCKER_CONTAINER_ID=$(docker ps -q --filter "name=$DC_CONTAINER_NAME")
docker exec -u root -it $DC_DOCKER_CONTAINER_ID /bin/bash