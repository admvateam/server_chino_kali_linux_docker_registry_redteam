# Starts from an Ubuntu base image
FROM ubuntu:22.04

# Sets environment variable to suppress prompts
ENV DEBIAN_FRONTEND=noninteractive

# Installs the required dependencies
RUN apt update -y && apt install -y \
    curl \
    git \
    openjdk-21-jdk \
    maven \
    unzip \
    wget \
    apt-transport-https \
    ca-certificates \
    software-properties-common \
    build-essential \
    ruby-full \
    npm \
    python3 \
    python3-pip \
    golang \
    gnupg \
    iputils-ping \
    telnet \
    vim \
    net-tools \
    jq \
    && apt clean && rm -rf /var/lib/apt/lists/*

# Resets DEBIAN_FRONTEND to avoid issues for subsequent commands
ENV DEBIAN_FRONTEND=dialog

# Sets Java environment variables
ENV JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
ENV PATH="$JAVA_HOME/bin:$PATH"

# Verifies Java installation
RUN java -version

# Installs the latest Gradle version
RUN GRADLE_LATEST_VERSION=$(curl -s https://services.gradle.org/versions/current | jq -r '.version') && \
    wget https://services.gradle.org/distributions/gradle-${GRADLE_LATEST_VERSION}-bin.zip -P /tmp && \
    unzip -d /opt/gradle /tmp/gradle-${GRADLE_LATEST_VERSION}-bin.zip && \
    ln -s /opt/gradle/gradle-${GRADLE_LATEST_VERSION}/bin/gradle /usr/bin/gradle

# Debugging: Verifies Gradle installation
RUN gradle --version

# Debugging: Verifies Maven installation
RUN mvn -version

# Downloads the latest release of Fortify Command Line Interface (FCLI) Utility dynamically
ENV FCLI_WORKDIR=/opt/fcli
RUN mkdir -p $FCLI_WORKDIR && \
    FCLI_LATEST_RELEASE_VERSION=$(curl -s https://api.github.com/repos/fortify/fcli/releases/latest | jq -r '.tag_name') && \
    FCLI_LATEST_RELEASE_URL="https://github.com//fortify/fcli/releases/download/$FCLI_LATEST_RELEASE_VERSION/fcli-linux.tgz" && \
    wget $FCLI_LATEST_RELEASE_URL -P /tmp && \
    tar -xzvf /tmp/fcli-linux*.tgz -C $FCLI_WORKDIR && \
    rm /tmp/fcli-linux*.tgz

# Debugging: Verifies the directory where the latest FCLI release has been downloaded
RUN ls -l $FCLI_WORKDIR

# Adds the directory containing fcli.sh from the downloaded release to the PATH
ENV PATH="/opt/fcli:$PATH"

# Creates a symbolic link for fcli.sh from the downloaded release fcli.sh as fcli
RUN ln -s /opt/fcli/fcli.sh /usr/bin/fcli

# Debugging: Verifies FCLI installation
RUN fcli --version

# Downloads the latest release of DependencyCheck dynamically
ENV DC_WORKDIR=/opt/DependencyCheck
RUN DC_LATEST_RELEASE_VERSION=$(curl -s https://api.github.com/repos/dependency-check/DependencyCheck/releases/latest | jq -r '.tag_name') && \
    DC_LATEST_RELEASE_NUMBER=$(echo $DC_LATEST_RELEASE_VERSION | sed 's/^v//') && \
    DC_LATEST_RELEASE_URL="https://github.com/dependency-check/DependencyCheck/releases/download/$DC_LATEST_RELEASE_VERSION/dependency-check-$DC_LATEST_RELEASE_NUMBER-release.zip" && \
    wget $DC_LATEST_RELEASE_URL -P /tmp && \
    unzip /tmp/dependency-check-*.zip -d $DC_WORKDIR && \
    rm /tmp/dependency-check-*.zip

# Debugging: Verifies the directory where the latest DependencyCheck release has been downloaded
RUN ls -l $DC_WORKDIR/dependency-check

# Adds the directory containing dependency-check.sh from the last release downloaded to the PATH
ENV PATH="/opt/DependencyCheck/dependency-check/bin:$PATH"

# Creates a symbolic link for dependency-check.sh as dependencycheck
RUN ln -s /opt/DependencyCheck/dependency-check/bin/dependency-check.sh /usr/bin/dependencycheck

# Debugging: Verifies DependencyCheck latest release installation
RUN dependencycheck -v

# Clones the DependencyCheck repository
RUN git clone https://github.com/dependency-check/DependencyCheck.git /tmp/DependencyCheck
ENV DC_REPOSITORY_DIRECTORY=$DC_WORKDIR/dependency-check-repository
RUN mv /tmp/DependencyCheck /tmp/dependency-check-repository
RUN mv /tmp/dependency-check-repository $DC_REPOSITORY_DIRECTORY

# Debugging: Verifies the directory where the repository of DependencyCheck repository has been cloned
RUN ls -l $DC_REPOSITORY_DIRECTORY

# Builds the DependencyCheck Repository Application with Maven
RUN cd $DC_REPOSITORY_DIRECTORY && mvn -s $DC_REPOSITORY_DIRECTORY/settings.xml install -DskipTests=true

# Adds the directory containing dependency-check.sh from the cloned repository to the PATH
ENV PATH="/opt/DependencyCheck/dependency-check-repository/cli/target/release/bin:$PATH"

# Creates a symbolic link for dependency-check.sh from the cloned repository dependency-check.sh as dependencycheckrepo
RUN ln -s /opt/DependencyCheck/dependency-check/bin/dependency-check.sh /usr/bin/dependencycheckrepo

# Debugging: Verifies DependencyCheck Repository installation
RUN dependencycheckrepo -v

# Debugging: Verifies where the repository of DependencyCheck repository target directory after building it with Maven
RUN ls -l $DC_REPOSITORY_DIRECTORY/target

# Sets DependencyCheck application data directory
ENV DC_DATA_DIRECTORY=/usr/share/dependency-check/data
RUN mkdir -p $DC_DATA_DIRECTORY

# Debugging: Verifies DependencyCheck application data new directory
RUN ls -l $DC_DATA_DIRECTORY

# Creates a directory for scan reports
ENV DC_SCAN_REPORTS_DIRECTORY=/opt/DependencyCheck/dependency-check-scan-reports
RUN mkdir -p $DC_SCAN_REPORTS_DIRECTORY

# Debugging: Verifies DependencyCheck application scan reports new directory
RUN ls -l $DC_SCAN_REPORTS_DIRECTORY

# Creates a directory for projects to scan with DependencyCheck
ENV DC_PROJECTS_TO_SCAN_DIRECTORY=/opt/DependencyCheck/dependency-check-projects-to-scan
RUN mkdir -p $DC_PROJECTS_TO_SCAN_DIRECTORY

# Debugging: Verifies DependencyCheck application projects to scan new directory
RUN ls -l $DC_PROJECTS_TO_SCAN_DIRECTORY

# Clones a dummy test application (Petclinic) to scan with DependencyCheck
RUN mkdir -p $DC_PROJECTS_TO_SCAN_DIRECTORY/Petclinic
RUN git clone https://github.com/varadharajanravi/Petclinic.git $DC_PROJECTS_TO_SCAN_DIRECTORY/Petclinic

# Copies the DependencyCheck Scan script template into the dummy test application (Petclinic) folder
COPY template_scripts/maven/dependency-check-scan-template-script.sh $DC_PROJECTS_TO_SCAN_DIRECTORY/Petclinic

# Grants execute permissions to the script
RUN chmod +x $DC_PROJECTS_TO_SCAN_DIRECTORY/Petclinic/dependency-check-scan-template-script.sh

# Debugging: Verifies where the dummy test application (Petclinic) has been cloned 
RUN ls -l $DC_PROJECTS_TO_SCAN_DIRECTORY/Petclinic

# Builds the dummy application (Petclinic) with Maven
#RUN mvn -f $DC_PROJECTS_TO_SCAN_DIRECTORY/Petclinic/pom.xml clean package

# Debugging: Verifies dummy test application target directory after building it with Maven
#RUN ls -l $DC_PROJECTS_TO_SCAN_DIRECTORY/Petclinic/target

# Clones a dummy test application (vulnerable-java-application) to scan with DependencyCheck
RUN mkdir -p $DC_PROJECTS_TO_SCAN_DIRECTORY/vulnerable-java-application
RUN git clone https://github.com/DataDog/vulnerable-java-application $DC_PROJECTS_TO_SCAN_DIRECTORY/vulnerable-java-application

# Copies the DependencyCheck Scan script template into the dummy test application (vulnerable-java-application) folder
COPY template_scripts/gradle/dependency-check-scan-template-script.sh $DC_PROJECTS_TO_SCAN_DIRECTORY/vulnerable-java-application

# Grants execute permissions to the script
RUN chmod +x $DC_PROJECTS_TO_SCAN_DIRECTORY/vulnerable-java-application/dependency-check-scan-template-script.sh

# Debugging: Verifies where the dummy test application (vulnerable-java-application) has been cloned 
RUN ls -l $DC_PROJECTS_TO_SCAN_DIRECTORY/vulnerable-java-application

# Builds the dummy application (vulnerable-java-application) with Gradle
#RUN mvn -f $DC_PROJECTS_TO_SCAN_DIRECTORY/Petclinic/pom.xml clean package

# Debugging: Verifies dummy test application (vulnerable-java-application) build directory after building it with Gradle
#RUN ls -l $DC_PROJECTS_TO_SCAN_DIRECTORY/vulnerable-java-application/build

# Sets up the working directory to DependencyCheck application location
WORKDIR $DC_WORKDIR

# Debugging: Verifies DependencyCheck application location with all the new changes
RUN ls -l $DC_WORKDIR

# Default ENTRYPOINT for DependencyCheck
CMD ["tail", "-f", "/dev/null"]