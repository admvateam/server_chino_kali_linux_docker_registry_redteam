#!/bin/bash

# Script that builds server-chino-kali-linux-docker-volume-registry-data Docker Volume, server-chino-kali-linux-docker-registry Docker Registry and tags/pushes some Docker Images

# Exits immediately if a command exits with a non-zero status
set -e

# Defines the variables
HOST_IP_ADDRESS="10.75.246.225"                                                                  		   # Server Chino Kali Linux Host IP address
REGISTRY_PORT="8443"                                                                             		   # Port of the Docker Registry
REGISTRY_URL="srv-kali-app01.telecom.arg.telecom.com.ar"                                         		   # Custom URL for the Docker Registry
VOLUME_NAME="server-chino-kali-linux-docker-volume-registry-data"                                		   # Docker Volume name
REGISTRY_NAME="server-chino-kali-linux-docker-registry"                                          		   # Docker Registry Container name
REGISTRY_IMAGE_NAME="registry"                                                                   		   # Docker Registry Image name
REGISTRY_TAG="latest"                                                                            		   # Docker Registry Tag name
REGISTRY_DATA_DIRECTORY="/var/lib/registry"                                                      		   # Docker Registry data directory inside the Docker Registry Container
REGISTRY_CERTIFICATES_DIRECTORY="/opt/certificates"                                               		   # Docker Registry directory where the Docker Registry certificates will be located
HOST_CERTIFICATES_DIRECTORY="/opt/Server_Chino_Kali_Docker_Registry/certificates"                		   # Host local directory of the certificates used by the Docker Registry
REGISTRY_PRIVATE_KEY="srv-kali-app01-decrypted.key"                                              		   # Decrypted private key to be used for the Docker Registry 
REGISTRY_SSL_CERTIFICATE="srv-kali-app01.crt"                                                    		   # Self-signed SSL certificate to be used for the Docker Registry
DC_IMAGE_NAME="dependency-check-sca"                                                             		   # DependencyCheck Docker Image name
DC_TAG_OS="ubuntu"                                                                               		   # Base OS used for the DependencyCheck Docker Image
DC_DOCKERFILE="/opt/Server_Chino_Kali_Docker_Registry/docker_management_scripts/dependency-check-sca.dockerfile"   # Path to the Dockerfile for the DependencyCheck Docker Image                                        

# Function to check the success of the last executed command
# Takes an error message as an argument and exits the script if the command failed
check_success() {
    local exit_code=$1
    local message=$2
    if [ $exit_code -ne 0 ]; then
        echo -e "\e[31mError: $message\e[0m"                                                     # Prints the error message in red
        exit $exit_code                                                                          # Exits the script with the captured failure status
    fi
}

# Creates a Docker Volume for this server
echo "Creating the Docker Volume '$VOLUME_NAME' for this server at $(date)..."

echo ""

docker volume create $VOLUME_NAME

echo ""

volume_creation_status=$?                                                                        # Captures the exit code immediately
check_success $volume_creation_status "Failed to create the '$VOLUME_NAME' Docker Volume." 

echo ""

# Lists the new Docker Volume 
docker volume ls | grep "$VOLUME_NAME"

echo ""

list_volume_status=$?                                                                            # Captures the exit code immediately
check_success $list_volume_status "Failed to find the '$VOLUME_NAME' Docker Volume." 

echo ""

# Inspects the new Docker Volume
echo "The New Docker Volume is the following: "
docker volume inspect $VOLUME_NAME

echo ""

inspect_volume_status=$?                                                                         # Captures the exit code immediately
check_success $inspect_volume_status "Failed to inspect the '$VOLUME_NAME' Docker Volume." 
echo -e "\e[33mDocker Volume '$VOLUME_NAME' has been created successfully!\e[0m"

echo ""

# Builds the Docker Registry for this server attached to the recently created Docker Volume
echo "Building the Docker Registry '$REGISTRY_NAME' and attaching it to the Docker Volume '$VOLUME_NAME' for this server at $(date)..."

echo ""

docker run -d -p $REGISTRY_PORT:$REGISTRY_PORT --name $REGISTRY_NAME -v $VOLUME_NAME:$REGISTRY_DATA_DIRECTORY -v $HOST_CERTIFICATES_DIRECTORY:$REGISTRY_CERTIFICATES_DIRECTORY -e REGISTRY_HTTP_ADDR=0.0.0.0:$REGISTRY_PORT -e REGISTRY_HTTP_TLS_CERTIFICATE=$REGISTRY_CERTIFICATES_DIRECTORY/$REGISTRY_SSL_CERTIFICATE -e REGISTRY_HTTP_TLS_KEY=$REGISTRY_CERTIFICATES_DIRECTORY/$REGISTRY_PRIVATE_KEY --restart unless-stopped $REGISTRY_IMAGE_NAME:$REGISTRY_TAG

echo ""

build_registry_status=$?                                                                         # Captures the exit code immediately
check_success $build_registry_status "Failed to build the '$REGISTRY_NAME' Docker Registry." 

echo ""

# Builds the Docker image for DependencyCheck
echo "Building the Docker Image for DependencyCheck at $(date)..."

echo ""

docker build --tag "$DC_IMAGE_NAME:$DC_TAG_OS" --file "$DC_DOCKERFILE" .

echo ""

build_image_status=$?                                                                            # Captures the exit code immediately
check_success $build_image_status "Failed to build the '$DC_IMAGE_NAME' Docker image." 

echo ""

# Lists the Docker images and filter by the newly created image for DependencyCheck
docker images | grep "$DC_IMAGE_NAME"

echo ""

list_image_status=$?                                                                             # Captures the exit code immediately
check_success $list_image_status "Failed to find the '$DC_IMAGE_NAME' Docker image." 
echo -e "\e[33mDocker Image '$DC_IMAGE_NAME' has been created successfully!\e[0m"

echo ""

# Tags the Docker Image for DependencyCheck to the Docker Registry
echo "Tagging the Docker Image '$DC_IMAGE_NAME' to the Docker Registry '$REGISTRY_NAME' at $(date)..."

echo ""

docker tag $DC_IMAGE_NAME:$DC_TAG_OS $REGISTRY_URL:$REGISTRY_PORT/$DC_IMAGE_NAME:$DC_TAG_OS

echo ""

dc_image_tag_to_registry_status=$?                                                               # Captures the exit code immediately
check_success $dc_image_tag_to_registry_status "Failed to tag the '$DC_IMAGE_NAME' Docker image to the '$REGISTRY_NAME' Docker Registry." 
echo -e "\e[33mDocker Image '$DC_IMAGE_NAME' has been tagged to the Docker Registry '$REGISTRY_NAME' successfully!\e[0m"

echo ""

# Pushes the Docker Image for DependencyCheck to the Docker Registry
echo "Pushing the Docker Image '$DC_IMAGE_NAME' to the Docker Registry '$REGISTRY_NAME' at $(date)..."

echo ""

docker push $REGISTRY_URL:$REGISTRY_PORT/$DC_IMAGE_NAME:$DC_TAG_OS

echo ""

dc_image_push_to_registry_status=$?                                                              # Captures the exit code immediately
check_success $dc_image_push_to_registry_status "Failed to push the '$DC_IMAGE_NAME' Docker image to the '$REGISTRY_NAME' Docker Registry."

echo ""

# Inspects the Docker Registry after tagging and pushing the Docker Image
echo "The New Docker Registry with the tagged and pushed new Docker Image is the following: "
docker inspect $REGISTRY_NAME

inspect_registry_status=$?                                                                       # Captures the exit code immediately
check_success $inspect_registry_status "Failed to inspect the '$REGISTRY_NAME' Docker Volume." 
echo -e "\e[33mDocker Image $DC_IMAGE_NAME has been pushed to the Docker Registry $REGISTRY_NAME successfully!\e[0m"

echo ""

# Shows the Docker Images that are currently in the Docker Registry
echo "The Docker Images that are currently in the Docker Registry '$REGISTRY_NAME' are: "
curl -k -X GET https://srv-kali-app01.telecom.arg.telecom.com.ar:8443/v2/_catalog | jq .

show_registry_images_status=$?                                                                   # Captures the exit code immediately
check_success $show_registry_images_status "Failed to show the '$REGISTRY_NAME' Docker Images."

# Prints a success message
echo -e "\e[32mExecution completed successfully!\e[0m"