#!/bin/bash

# Script that scans a project with DependencyCheck

# Exits immediately if a command exits with a non-zero status
set -e

# Defines the variables
DC_ENGINE="dependencycheck"                                                                                  # DependencyCheck engine to call the DependencyCheck cli
DC_SCAN_REPORTS_DIRECTORY="/opt/DependencyCheck/dependency-check-scan-reports"                               # Directory where DependencyCheck scan reports will be stored
DC_PROJECT_ROOT_TO_SCAN_DIRECTORY="/opt/DependencyCheck/dependency-check-projects-to-scan/Petclinic/target"  # Root directory of the project to scan with DependencyCheck
DC_PROJECT_NAME="Petclinic"                                                                                  # The name of the project being scanned
DC_PROJECT_SCAN_REPORT_DIRECTORY="$DC_SCAN_REPORTS_DIRECTORY/$DC_PROJECT_NAME"                               # Full path where the DependencyCheck scan report for the project will be stored
DC_SCAN_LOG_FILE_NAME="${DC_PROJECT_NAME}_scan.log"                                                          # Name of the log file for the DependencyCheck scan process
DC_SCAN_LOG_FILE_PATH="$DC_PROJECT_SCAN_REPORT_DIRECTORY/$DC_SCAN_LOG_FILE_NAME"                             # Full path to the DependencyCheck scan log file
DC_NVD_API_KEY="76b5b043-c65a-4006-8ba1-43650ac19985"                                                        # API key for the National Vulnerability Database (NVD) used by DependencyCheck
DC_SCAN_FILE_NAME="${DC_PROJECT_NAME}-dependency-check-report.json"                                          # The name of the DependencyCheck report file (in JSON format)
DC_PROJECT_SCAN_REPORT_FULL="$DC_PROJECT_SCAN_REPORT_DIRECTORY/$DC_SCAN_FILE_NAME"                           # Full path to the JSON DependencyCheck scan report
DC_PROJECT_SCAN_REPORT_ZIP_FILE="${DC_PROJECT_NAME}-dependencycheck-report.zip"                              # Name of the zip file that will contain the DependencyCheck scan report
ENGINE_TYPE="OWASP_DEPCHECK"                                                                                 # The type of engine to be used in the DependencyCheck scan upload to Fortify SSC
FORTIFY_TOKEN="ZjM2MTA2NWMtYmYxMi00YTI2LWJjY2EtNjg2MmNiNWZkM2U5"                                             # Fortify token used for authentication with the Fortify SSC server
FORTIFY_URL="https://fortify.telecom.arg.telecom.com.ar:8443/ssc"                                            # URL of the Fortify SSC server
FORTIFY_SESSION_NAME="DependencyCheckScanUpload"                                                             # Session name for the Fortify SSC session during the scan upload process with fcli
FORTIFY_APPLICATION_VERSION_NAME="dependency-check-scan"                                                     # Fortify SSC Appliaction Version where the DependencyCheck scan results will be stored
FORTIFY_SSC_API_URL="https://fortify.telecom.arg.telecom.com.ar:8443/ssc/api/v1"

# Scan report directory preparation step
echo "Proceeding to check if the project scan report directory for '$DC_PROJECT_NAME' exists..."

echo ""

# Checks if the project scan report directory exists (it creates it if it doesn't exist)
if [ -d $DC_PROJECT_SCAN_REPORT_DIRECTORY ]; then
  echo -e "\e[32mScan report folder for $DC_PROJECT_NAME project exists!\e[0m"

  echo ""
else
  echo -e "\e[31mScan report folder for '$DC_PROJECT_NAME' project doesn't exist!\e[0m"

  echo ""

  echo -e "\e[33mCreating the project scan report directory for '$DC_PROJECT_NAME' project\e[0m"

  echo ""

  # Creates the directory where the scan results and logs of the project will be saved
  mkdir -p $DC_PROJECT_SCAN_REPORT_DIRECTORY
  ls -l $DC_PROJECT_SCAN_REPORT_DIRECTORY

  echo ""

  echo -e "\e[32mScan report folder for '$DC_PROJECT_NAME' has been created successfully!\e[0m"

  echo ""
fi

# Checking Project Root files step (checks the files of the Project Root in order to find a build engine like Maven, Gradle, etc)
if [[ -f "build.gradle" ]]; then
    DC_SCAN_PROJECT_BUILD_TYPE="gradle"
elif [[ -f "pom.xml" ]]; then
    DC_SCAN_PROJECT_BUILD_TYPE="maven"
else
   DC_SCAN_PROJECT_BUILD_TYPE="other"
fi

# Case statement for running DependencyCheck with the correct Java build plugin or normally (Maven or Gradle)
case $DC_SCAN_PROJECT_BUILD_TYPE in
    "gradle")
        echo -e "\e[33mThe project root directory of '$DC_PROJECT_NAME' has Gradle files.\e[0m"

        echo ""

        echo "Checking Gradle files of the project root directory of'$DC_PROJECT_NAME' project..."

        echo ""

        # Checks in the Project Root of the project to scan for Gradle build files
        if [[ -f "build.gradle" || -f "build.gradle.kts" ]]; then
          echo -e "\e[33mFound Gradle project files in the '$DC_PROJECT_NAME' project.\e[0m"

          echo ""

          echo -e "\e[33mProceeding to check if the project root directory of'$DC_PROJECT_NAME' project has a build directory.\e[0m"

          echo ""

          # Checks for the build directory (indicates that a build artifacts exist)
          if [[ -d "build" ]]; then
            echo -e "\e[33mBuild directory found. The project '$DC_PROJECT_NAME' has been built with Gradle.\e[0m"

            echo ""

            # DependencyCheck scan step (with Gradle Plugin)
            echo -e "\e[33mProceeding to scan '$DC_PROJECT_NAME' project with DependencyCheck with Gradle plugin...\e[0m"

            echo ""

            # Runs the DependencyCheck scan with gradle
            gradle dependencyCheckAnalyze

            echo ""

            echo -e "\e[32mScan with DependencyCheck Gradle Plugin of the '$DC_PROJECT_NAME' project has been successful!\e[0m"

            echo ""
          else
            echo -e "\e[31mNo build directory found in '$DC_PROJECT_NAME' project. The project may not have been built with Gradle yet.\e[0m"

            echo ""

	    echo -e "\e[33mProceeding to build The project '$DC_PROJECT_NAME' with Gradle...\e[0m"

	    echo ""

            # Gets the current version of DependencyCheck
            DC_VERSION=$(dependencycheck -v | awk '{print $NF}')

	    # Defines the Gradle build file
	    GRADLE_BUILD_FILE="build.gradle"
	
	    # Defines the DependencyCheck configuration block for the build.gradle file
            DEPENDENCY_CHECK_BLOCK="
	    dependencyCheck {
    	 	format = 'JSON'
    		nvd.apiKey = '$DC_NVD_API_KEY'
    		outputDirectory = '$DC_SCAN_REPORTS_DIRECTORY/$DC_PROJECT_NAME/$DC_SCAN_FILE_NAME'
            }"

	    # Modifies the Build Gradle file to run DependencyCheck Scan
            if [[ ! -f "$BUILD_FILE" ]]; then
              sed -i "/plugins {/a\    id 'org.owasp.dependencycheck' version '$DC_VERSION'" "$GRADLE_BUILD_FILE"
              echo "$DEPENDENCY_CHECK_BLOCK" >> "$GRADLE_BUILD_FILE"
            fi

	    # Builds the application with Gradle
            ./gradlew clean build

            echo ""

            echo -e "\e[32m'$DC_PROJECT_NAME' project has been successfully built with Gradle!\e[0m"

            echo ""
	    
	    # DependencyCheck scan step (with Gradle Plugin)
            echo -e "\e[33mProceeding to scan '$DC_PROJECT_NAME' project with DependencyCheck Gradle plugin...\e[0m"

            echo ""

            # Runs the DependencyCheck scan with gradle
            gradle dependencyCheckAnalyze

            echo ""

            echo -e "\e[32mScan with DependencyCheck Gradle Plugin of the '$DC_PROJECT_NAME' project has been successful!\e[0m"

            echo ""
          fi
        else
          echo -e "\e[33mNo Gradle project files detected in the Project Root of '$DC_PROJECT_NAME' project.\e[0m"
        fi
        ;;
    "maven")
        echo -e "\e[33mThe project root directory of '$DC_PROJECT_NAME' has Maven files.\e[0m"

        echo ""

        echo "Checking Maven files of the project root directory of'$DC_PROJECT_NAME' project..."
        
        echo ""

        # Checks the Project Root of the project to scan is from a Maven project
	if [ -f "pom.xml" ] || [ -f "mvnw" ] || [ -f "mvnw.cmd" ]; then
    	
 	  echo -e "\e[33mFound Maven project files in the '$DC_PROJECT_NAME' project.\e[0m"

    	  echo ""

          echo "Checking if the pom.xml file of the project root directory of'$DC_PROJECT_NAME' has a valid pom.xml file..."
        
          echo ""

          # Checks if pom.xml is valid (contains <project> tag)
    	  if [ -f "pom.xml" ] && grep -q "<project" pom.xml; then
            echo -e "\e[33m'$DC_PROJECT_NAME' project has a valid Maven pom.xml file.\e[0m"

            echo ""

            echo -e "\e[33mProceeding to check if the project root directory of'$DC_PROJECT_NAME' project has a target directory.\e[0m"

            echo ""        

            # Checks for the target directory (indicates that a build artifacts exist)
            if [ -d "target" ]; then
              echo -e "\e[33mTarget directory found. The project '$DC_PROJECT_NAME' has been built with Maven.\e[0m"

              echo ""

              # DependencyCheck scan step (with Maven Plugin)
              echo -e "\e[33mProceeding to scan '$DC_PROJECT_NAME' project with DependencyCheck with Maven plugin...\e[0m"

              echo ""
            
              # Runs the scan and generates a log file of the project with DependencyCheck (using Maven Plugin)
              mvn org.owasp:dependency-check-maven:check -Dformat=JSON -Dodc.outputDirectory=$DC_PROJECT_SCAN_REPORT_FULL -Dodc.scanPlugins=true -Dodc.prettyPrint=true -DnvdApiKey=$DC_NVD_API_KEY -Dlog=$DC_SCAN_LOG_FILE_PATH
                       
              echo ""

              echo -e "\e[32mScan with DependencyCheck Maven Plugin of the '$DC_PROJECT_NAME' project has been successful!\e[0m"

              echo ""
            else
              echo -e "\e[31mNo target directory found in '$DC_PROJECT_NAME' project. The project may not have been built with Maven yet.\e[0m"
            
              echo ""

              echo -e "\e[33mProceeding to build The project '$DC_PROJECT_NAME' with Maven...\e[0m"

	      echo ""
              
              # Builds the application with Maven
              mvn -f pom.xml clean install

              echo ""

              echo -e "\e[32m'$DC_PROJECT_NAME' project has been successfully built with Maven!\e[0m"

              echo ""

	      echo -e "\e[33mProceeding to scan '$DC_PROJECT_NAME' project with DependencyCheck with Maven plugin...\e[0m"

              echo ""
            
              # Runs the scan and generates a log file of the project with DependencyCheck (using Maven Plugin)
              mvn org.owasp:dependency-check-maven:check -Dformat=JSON -Dodc.outputDirectory=$DC_PROJECT_SCAN_REPORT_FULL -Dodc.scanPlugins=true -Dodc.prettyPrint=true -DnvdApiKey=$DC_NVD_API_KEY -Dlog=$DC_SCAN_LOG_FILE_PATH
                       
              echo ""

              echo -e "\e[32mScan with DependencyCheck Maven Plugin of the '$DC_PROJECT_NAME' project has been successful!\e[0m"

              echo ""
            fi
          else
            echo -e "\e[31mpom.xml is missing or invalid. This '$DC_PROJECT_NAME' project may not be a project built with Maven.\e[0m"

            echo ""
        
            echo "Verify the pom.xml from the '$DC_PROJECT_NAME' project to be a valid one before running DependencyCheck scan."
            
            exit 1
          fi
        else
          echo -e "\e[33mNo Maven project files detected in the Project Root of '$DC_PROJECT_NAME' project.\e[0m"  
        fi
        ;;
    "other")
        echo -e "\e[33mThe project root directory of '$DC_PROJECT_NAME' ha no Maven nor Gradle files.\e[0m"
        
        echo ""

        # If Build type is not Gradle or Maven runs DependencyCheck scan directly
        if [[ $DC_SCAN_PROJECT_BUILD_TYPE == "other" ]]; then
          # DependencyCheck scan step (without any Plugins)
          echo -e "\e[33mProceeding to scan '$DC_PROJECT_NAME' project with DependencyCheck directly without any plugins...\e[0m"

          echo ""

   	  # Runs the scan and generates a log file of the project with DependencyCheck
   	  dependencycheck -f JSON --out $DC_PROJECT_SCAN_REPORT_FULL -s $DC_PROJECT_ROOT_TO_SCAN_DIRECTORY --nvdApiKey $DC_NVD_API_KEY -l $DC_SCAN_LOG_FILE_PATH

          echo ""

          echo -e "\e[32mScan with DependencyCheck of the '$DC_PROJECT_NAME' project has been successful!\e[0m"
        else
  	  echo -e "\e[33mThe project files in the Project Root of '$DC_PROJECT_NAME' project are not built in any external libraries, frameworks, or modules (dependencies).\e[0m"
        
  	  echo ""

  	  echo -e "\e[31mUnable to start a DependencyCheck scan for '$DC_PROJECT_NAME' project. No dependencies found on the project.\e[0m"   

  	  exit 1 
	fi
        ;;
    *)
        echo -e "\e[33mThe project files in the Project Root of '$DC_PROJECT_NAME' project are not built in any external libraries, frameworks, or modules (dependencies).\e[0m"
        
        echo ""

        echo -e "\e[31mUnable to start a DependencyCheck scan for '$DC_PROJECT_NAME' project. No dependencies found on the project.\e[0m"   

        exit 1        
        ;;
esac

echo ""
        
# Update of local NVD data cache step
echo -e "\e[33mProceeding to update the local NVD data cache...\e[0m"

echo ""

# Updates the local NVD data cache
dependencycheck --nvdApiKey $DC_NVD_API_KEY --updateonly

echo ""

echo -e "\e[32mUpdate of the local NVD data cache has been successful!\e[0m"

echo ""

# Export of the DependencyCheck scan results to Fortify Software Security Center (SSC) step
echo -e "\e[33mProceeding to export '$DC_PROJECT_NAME' project dependencycheck scan results to Fortify SSC...\e[0m"

echo ""

# Creates the scan info file
echo -e "\e[33mCreating the scan info file for exporting to Fortify SSC...\e[0m"

echo ""

cd $DC_PROJECT_SCAN_REPORT_DIRECTORY
echo "engineType=OWASP_DEPCHECK" > scan.info
DC_SCAN_INFO_FILE="scan.info"

echo ""

# Zips the DependencyCheck scan results of the $DC_PROJECT_NAME project
echo -e "\e[33mZipping the scan info file and DependencyCheck scan results...\e[0m"

echo ""

zip $DC_PROJECT_NAME-dependencycheck-report.zip $DC_SCAN_FILE_NAME $DC_SCAN_INFO_FILE

echo ""

echo -e "\e[32mZipping of the scan report and scan info files of the $DC_PROJECT_NAME project scan has been done successfully!\e[0m"

echo ""

echo -e "\e[33mLogging into Fortify SSC...\e[0m"

echo ""

# Logs in to Fortify SSC using the provided token, URL, and session name
fcli ssc session login --token=$FORTIFY_TOKEN --url="$FORTIFY_URL" --ssc-session="$FORTIFY_SESSION_NAME" -k

echo ""

# Creates the Fortify Application and Application version in the Fortify SSC in case if they not exist
echo -e "\e[33mCreating the Fortify Application '$DC_PROJECT_NAME' and '$FORTIFY_APPLICATION_VERSION_NAME' Application Version...\e[0m"
FORTIFY_APP_AND_VERSION_CREATION_STATUS=$(fcli ssc appversion create "$DC_PROJECT_NAME":"$FORTIFY_APPLICATION_VERSION_NAME" --auto-required-attrs --skip-if-exists --issue-template 'Prioritized High Risk Issue Template' --ssc-session="$FORTIFY_SESSION_NAME" | awk 'NR>1 {print $NF}')

# Checks if the Fortify Application and Application Version is already existing
if [ "$FORTIFY_APP_AND_VERSION_CREATION_STATUS" = "SKIPPED_EXISTING" ]; then
    echo -e "\e[33mFortify Application '$DC_PROJECT_NAME' and '$FORTIFY_APPLICATION_VERSION_NAME' Application Version have been previously created\e[0m"

    echo ""
else
    echo -e "\e[33mFortify Application '$DC_PROJECT_NAME' and '$FORTIFY_APPLICATION_VERSION_NAME' Application Version have been recently created\e[0m"

    echo ""

    # Modifying the Processing Rules of the new Application Version
    echo -e "\e[33mModifying the Fortify Processing Rules from the '$FORTIFY_APPLICATION_VERSION_NAME' Application Version related to the '$DC_PROJECT_NAME' Application...\e[0m"
    FORTIFY_APPLICATION_VERSION_ID=$(fcli ssc av get $DC_PROJECT_NAME:$FORTIFY_APPLICATION_VERSION_NAME --ssc-session="$FORTIFY_SESSION_NAME" | grep '^id:' | head -n 1 | awk '{print $2}')

    echo ""

    FORTIFY_PROCESSING_RULES_UPDATE=$(curl -k "$FORTIFY_SSC_API_URL/projectVersions/$FORTIFY_APPLICATION_VERSION_ID/resultProcessingRules" \
        -X 'PUT' \
        -H "Authorization: FortifyToken $FORTIFY_TOKEN" \
        -H 'Accept: application/json, text/plain, */*' \
        -H 'Content-Type: application/json' \
        --data-raw '[{"displayName":"Require approval if the Build Project is different between scans","identifier":"com.fortify.manager.BLL.processingrules.BuildProjectProcessingRule","enabled":false,"displayable":true},{"displayName":"Check external metadata file versions in scan against versions on server.","identifier":"com.fortify.manager.BLL.processingrules.ExternalListVersionProcessingRule","enabled":false,"displayable":true},{"displayName":"Require approval if file count differs by more than 10%","identifier":"com.fortify.manager.BLL.processingrules.FileCountProcessingRule","enabled":false,"displayable":true},{"displayName":"Perform Force Instance ID migration on upload","identifier":"com.fortify.manager.BLL.processingrules.ForceMigrationProcessingRule","enabled":false,"displayable":true},{"displayName":"Require approval if result has Fortify Java Annotations","identifier":"com.fortify.manager.BLL.processingrules.FortifyAnnotationsProcessingRule","enabled":false,"displayable":true},{"displayName":"Require approval if line count differs by more than 10%","identifier":"com.fortify.manager.BLL.processingrules.LOCCountProcessingRule","enabled":false,"displayable":true},{"displayName":"Automatically perform Instance ID migration on upload","identifier":"com.fortify.manager.BLL.processingrules.MigrationProcessingRule","enabled":true,"displayable":true},{"displayName":"Require approval if the engine version of a scan is newer than the engine version of the previous scan","identifier":"com.fortify.manager.BLL.processingrules.NewerEngineVersionProcessingRule","enabled":false,"displayable":true},{"displayName":"Ignore SCA scans performed in Quick Scan mode","identifier":"com.fortify.manager.BLL.processingrules.QuickScanProcessingRule","enabled":true,"displayable":true},{"displayName":"Require approval if the rulepacks used in the scan do not match the rulepacks used in the previous scan","identifier":"com.fortify.manager.BLL.processingrules.RulePackVersionProcessingRule","enabled":false,"displayable":true},{"displayName":"Require approval if SCA or WebInspect Agent scan does not have valid certification","identifier":"com.fortify.manager.BLL.processingrules.ValidCertificationProcessingRule","enabled":false,"displayable":true},{"displayName":"Require approval if result has analysis warnings","identifier":"com.fortify.manager.BLL.processingrules.WarningProcessingRule","enabled":false,"displayable":true},{"displayName":"Warn if audit information includes unknown custom tag","identifier":"com.fortify.manager.BLL.processingrules.UnknownOrDisallowedAuditedAttrChecker","enabled":true,"displayable":true},{"displayName":"Require the issue audit permission to upload audited analysis files","identifier":"com.fortify.manager.BLL.processingrules.AuditedAnalysisRule","enabled":true,"displayable":true},{"displayName":"Disallow upload of analysis results that change values of hidden tags ","identifier":"com.fortify.manager.BLL.processingrules.HiddenTagAuditsAnalysisRule","enabled":false,"displayable":true},{"displayName":"Disallow upload of analysis results if there is one pending approval","identifier":"com.fortify.manager.BLL.processingrules.PendingApprovalChecker","enabled":false,"displayable":true},{"displayName":"Disallow approval for processing if an earlier artifact requires approval","identifier":"com.fortify.manager.BLL.processingrules.VetoCascadingApprovalProcessingRule","enabled":false,"displayable":true}]' \
        --compressed \
        --insecure )

    echo ""

    echo "$FORTIFY_PROCESSING_RULES_UPDATE" | jq .

    echo ""

    echo -e "\e[32mUpdate of the Fortify Processing Rules of the '$FORTIFY_APPLICATION_VERSION_NAME' Application version related to the '$DC_PROJECT_NAME' Application has been done successfully!\e[0m"

    echo ""
fi

echo ""

# Uploads the artifact for the specified Application Version using the OWASP DependencyCheck engine
echo -e "\e[33mUploading the DependencyCheck scan into the '$FORTIFY_APPLICATION_VERSION_NAME' Fortify Application Version related to the $DC_PROJECT_NAME Fortify Application...\e[0m"

echo ""

fcli ssc artifact upload -f $DC_PROJECT_SCAN_REPORT_DIRECTORY/$DC_PROJECT_NAME-dependencycheck-report.zip --appversion $DC_PROJECT_NAME:$FORTIFY_APPLICATION_VERSION_NAME --engine-type $ENGINE_TYPE --ssc-session="$FORTIFY_SESSION_NAME"

echo ""

# Logs out from the Fortify SSC session identified
echo -e "\e[33mLogging out from Fortify SSC...\e[0m"

echo ""

fcli ssc session logout --ssc-session="$FORTIFY_SESSION_NAME"

echo ""

echo -e "\e[32mDependencyCheck scan report has been successfully uploaded into the Appliaction Version '$FORTIFY_APPLICATION_VERSION_NAME' from the '$DC_PROJECT_NAME' Application!\e[0m"

echo ""

# Prints an ending message
echo -e "\e[32mExecution completed successfully!\e[0m"