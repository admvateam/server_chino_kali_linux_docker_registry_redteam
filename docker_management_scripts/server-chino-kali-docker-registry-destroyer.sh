#!/bin/bash

# Script that destroys server-chino-kali-linux-docker-volume-registry-data Docker Volume, server-chino-kali-linux-docker-registry Docker Registry and the Docker Images related to them

# Exits immediately if a command exits with a non-zero status
set -e

# Defines the variables
HOST_IP_ADDRESS="10.75.246.225"                                        # Server Chino Kali Linux Host IP address
REGISTRY_PORT="8443"                                                   # Port of the Docker Registry
REGISTRY_URL="srv-kali-app01.telecom.arg.telecom.com.ar"               # Custom URL for the Docker Registry
VOLUME_NAME="server-chino-kali-linux-docker-volume-registry-data"      # Docker Volume name
REGISTRY_NAME="server-chino-kali-linux-docker-registry"                # Docker Registry name
REGISTRY_IMAGE_NAME="registry"                                         # Docker Registry Image name
REGISTRY_TAG="latest"                                                  # Docker Registry Tag name
DC_IMAGE_NAME="dependency-check-sca"                                   # DependencyCheck Docker Image name
DC_BASE_OS="ubuntu"                                                    # Base OS or Tag of the DependencyCheck Docker Image

# Function to check the success of the last executed command
# Takes an error message as an argument and exits the script if the command failed
check_success() {
    local exit_code=$1
    local message=$2
    if [ $exit_code -ne 0 ]; then
        echo -e "\e[31mError: $message\e[0m"                           # Prints the error message in red
        exit $exit_code                                                # Exits the script with the captured failure status
    fi
}

# Stops the Docker Registry $REGISTRY_NAME
echo "Stopping the Docker Registry '$REGISTRY_NAME' at $(date)..."

echo ""

REGISTRY_CONTAINER_ID=$(docker ps -a -q --filter "name=$REGISTRY_NAME")
if [ -n "$REGISTRY_CONTAINER_ID" ]; then
    # Handle case where multiple containers are found
    CONTAINER_COUNT=$(echo "$REGISTRY_CONTAINER_ID" | wc -w)
    if [ $CONTAINER_COUNT -gt 1 ]; then
        echo -e "\e[33mMultiple containers found for '$REGISTRY_NAME'. Please specify which one to stop.\e[0m"
        exit 1
    fi

    docker stop "$REGISTRY_CONTAINER_ID"
    registry_stop_status=$?                                            # Captures the exit code immediately
    check_success $registry_stop_status "Failed to stop the registry container '$REGISTRY_NAME'."
    
    echo ""

    echo -e "\e[32mDocker Registry Container '$REGISTRY_NAME' has been stopped!\e[0m"
else
    echo -e "\e[33mNo running container found with the name '$REGISTRY_NAME'.\e[0m"
fi

echo ""

# Deletes the Docker Registry Container
echo "Deletes the Docker Registry '$REGISTRY_NAME' at $(date)..."

echo ""

if [ -n "$REGISTRY_CONTAINER_ID" ]; then
    docker container rm "$REGISTRY_CONTAINER_ID"
    registry_container_deletion_status=$?                              # Captures the exit code immediately
    check_success $registry_container_deletion_status "Failed to remove the registry container '$REGISTRY_NAME'."
    
    echo ""

    echo -e "\e[33mDocker Registry Container '$REGISTRY_NAME' has been removed!\e[0m"
else
    echo -e "\e[33mNo container found to remove with '$REGISTRY_NAME' as name.\e[0m"
fi

echo ""

# Deletes the Docker Registry Image
echo "Deletes the Docker Registry Image '$REGISTRY_IMAGE_NAME' at $(date)..."

echo ""

REGISTRY_IMAGE_ID=$(docker images | grep "$REGISTRY_IMAGE_NAME" | grep "$REGISTRY_TAG" | awk '{print $3}')
if [ -n "$REGISTRY_IMAGE_ID" ]; then
    docker image rm "$REGISTRY_IMAGE_ID"  
    registry_image_deletion_status=$?                                  # Captures the exit code immediately
    check_success $registry_image_deletion_status "Failed to remove the image '$REGISTRY_IMAGE_NAME:$REGISTRY_TAG'."
    
    echo ""
    
    echo -e "\e[33mDocker Image '$REGISTRY_IMAGE_NAME:$REGISTRY_TAG' has been removed!\e[0m"
else
    echo -e "\e[33mNo Docker Image found for '$REGISTRY_IMAGE_NAME:$REGISTRY_TAG'.\e[0m"
fi

echo ""

# Destroys the Docker Volume $VOLUME_NAME
echo "Destroying the Docker Volume '$VOLUME_NAME' at $(date)..."

echo ""

docker volume rm $VOLUME_NAME

echo ""

volume_deletion_status=$?                                               # Captures the exit code immediately
check_success $volume_deletion_status "Failed to delete the $VOLUME_NAME Docker Volume." 

echo ""

# Lists the current list of Docker Volumes
docker volume ls

echo ""

list_volumes_status=$?                                                 # Captures the exit code immediately
check_success $list_volumes_status "Failed to find the Docker Volume list."

echo ""

# Removes the Tag of the DependencyCheck Image
docker rmi $REGISTRY_URL:$REGISTRY_PORT/$DC_IMAGE_NAME:$DC_BASE_OS

echo ""

dc_image_untag_from_registry_status=$?                                 # Captures the exit code immediately
check_success $dc_image_untag_from_registry_status "Failed to untag the '$DC_IMAGE_NAME' Docker image to the '$REGISTRY_NAME' Docker Registry." 
echo -e "\e[33mDocker Image '$DC_IMAGE_NAME' has been untagged to the Docker Registry '$REGISTRY_NAME' successfully!\e[0m"


# Deletes the Docker Image for DependencyCheck
echo "Removing the Docker Image '$DC_IMAGE_NAME' at $(date)..."

echo ""

DC_IMAGE_ID=$(docker images | grep "$DC_IMAGE_NAME" | grep "$DC_BASE_OS" | awk '{print $3}')
if [ -n "$DC_IMAGE_ID" ]; then
    docker image rm "$DC_IMAGE_ID"  
    dc_image_deletion_status=$?                                        # Captures the exit code immediately
    check_success $dc_image_deletion_status "Failed to remove the image '$DC_IMAGE_NAME:$DC_BASE_OS'."
    
    echo ""
    
    echo -e "\e[33mDocker Image '$DC_IMAGE_NAME:$DC_BASE_OS' has been removed!\e[0m"
else
    echo -e "\e[33mNo Docker Image found for '$DC_IMAGE_NAME:$DC_BASE_OS'.\e[0m"
fi

echo ""

# Prints a success message
echo -e "\e[32mExecution completed successfully!\e[0m"
