#!/bin/bash

# Script that destroys the Docker Image and Container for DependencyCheck

# Exits immediately if a command exits with a non-zero status
set -e

# Defines the variables
DC_IMAGE_NAME="srv-kali-app01.telecom.arg.telecom.com.ar:8443/dependency-check-sca"
DC_IMAGE_TAG_OS="ubuntu"
DC_CONTAINER_NAME="dependency-check-sca"

# Function to check the success of the last executed command
check_success() {
    local exit_code=$1
    local message=$2
    if [[ "$exit_code" -ne 0 ]]; then
        echo -e "\e[31mError: $message\e[0m"
        exit "$exit_code"
    fi
}

# Stops the DependencyCheck Docker Container
echo "Stopping the Docker Container '$DC_CONTAINER_NAME' at $(date)..."

echo ""

DC_CONTAINER_ID=$(docker ps -a -q --filter "name=$DC_CONTAINER_NAME")
if [[ -n "$DC_CONTAINER_ID" ]]; then
    docker stop "$DC_CONTAINER_ID"
    dc_docker_container_stop_status=$?
    check_success $dc_docker_container_stop_status "Failed to stop the container '$DC_CONTAINER_ID'."
    
    echo -e "\e[32mDocker Container '$DC_CONTAINER_NAME' has been stopped!\e[0m"
else
    echo -e "\e[33mNo running Docker Container found with the name '$DC_CONTAINER_NAME'.\e[0m"
fi

echo ""

# Removes the DependencyCheck Docker Container
echo "Removing the Docker Container '$DC_CONTAINER_NAME' at $(date)..."

echo ""

if [[ -n "$DC_CONTAINER_ID" ]]; then
    docker container rm "$DC_CONTAINER_ID"
    dc_docker_container_rm_status=$?
    check_success $dc_docker_container_rm_status "Failed to remove the container '$DC_CONTAINER_NAME'."
    
    echo -e "\e[33mDocker Container '$DC_CONTAINER_NAME' has been removed!\e[0m"
else
    echo -e "\e[33mNo Docker Container named '$DC_CONTAINER_NAME' found to remove.\e[0m"
fi

echo ""

# Deletes the DependencyCheck Docker Image
echo "Removing the Docker Image '$DC_IMAGE_NAME' at $(date)..."

echo ""

DC_IMAGE_ID=$(docker images | grep "$DC_IMAGE_NAME" | grep "$DC_IMAGE_TAG_OS" | awk '{print $3}')
if [[ -n "$DC_IMAGE_ID" ]]; then
    docker image rm "$DC_IMAGE_ID"
    dc_docker_image_rm_status=$?
    check_success $dc_docker_image_rm_status "Failed to remove the Docker Image '$DC_IMAGE_ID'."
    
    echo -e "\e[33mDocker Image '$DC_IMAGE_ID' has been removed!\e[0m"
else
    echo -e "\e[33mNo Docker Image named '$DC_IMAGE_ID' found to remove.\e[0m"
fi

echo ""

echo -e "\e[32mExecution completed successfully!\e[0m"
