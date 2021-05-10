#!/bin/bash
set -e -o pipefail
cat > _customer_script.sh <<'EOF_CUSTOMER_SCRIPT'
#!/bin/bash
set -e -o pipefail
cat > _pre_script.sh <<'EOF_PRE_SCRIPT'
if [ -s ~/.nvm/nvm.sh ]; then
  . ~/.nvm/nvm.sh
fi
#!/bin/bash

EOF_PRE_SCRIPT
source _pre_script.sh
cat > _cust_script.sh <<'EOF_REAL_CUSTOMER_SCRIPT'
#!/bin/bash

export PATH=/opt/IBM/node-v6.7.0/bin:$PATH

npm install -g newman
npm i npm@latest -g newman-reporter-html

newman run "https://www.getpostman.com/collections/8a0c9bc08f062d12dcda" -r html,cli --reporter-html-export /home/results/report.html &> newmanResults.txt

git checkout -f HTMLreports

cp ./newmanResults.txt ./test/results/newmanResults.txt

cp /home/results/report.html ./test/results/report.html

git add .

git config user.email gustaf.olsson@enfogroup.com
git config user.name GusOls

git commit -m "commit of latest test results html and newman result txt files"

git push origin HTMLreports
EOF_REAL_CUSTOMER_SCRIPT
source _cust_script.sh
cat > _post_script.sh <<'EOF_POST_SCRIPT'
#!/bin/bash
cd "$WORKSPACE"
if [ -d "$ARCHIVE_DIR" ]; then
skip_artifact_upload=false
artifact_files_size=$(du -sm "$ARCHIVE_DIR" | tr -s [:space:] ' ' | cut -d ' ' -f 1)
artifact_files=$(find "$ARCHIVE_DIR" | wc -l)
if [ "$PIPELINE_DEBUG_SCRIPT" == "true" ]; then
echo _DEBUG:ARTIFACT_FILES_SIZE:$artifact_files_size
echo _DEBUG:ARTIFACT_FILES:$artifact_files
fi
if [ "$skip_artifact_upload" == "false" ]; then
if [ "$PIPELINE_DEBUG_SCRIPT" == "true" ]; then
current_time=$(echo $(($(date +%s%N)/1000000)))
fi
export_variable="-x _pipeline_script.sh -x _customer_script.sh -x _cust_script.sh -x _codestation_script.sh"
export_variable="$export_variable -x _toolchain.json -x _env"
if test -f '.csignore'; then
while read -r line;
do
if test -n "$line"; then
if echo "$line" | grep -q '^[^\\]*$'; then
if echo "$line" | grep -q '^[0-9A-Za-z\/\.\-\_\*]*$'; then
export_variable="$export_variable -x $line"
fi
fi
fi
done < .csignore
else
export_variable="$export_variable -x /.git*"
fi
export ZIP_EXCLUDES="$export_variable"
CURL_VERBOSITY="--silent"
if [ "$PIPELINE_DEBUG_SCRIPT" == "true" ]; then CURL_VERBOSITY="-vvvv"; fi
echo "Preparing the build artifacts..."
curl $CURL_VERBOSITY --fail --retry 3 --retry-delay 5 --connect-timeout 10 --output _codestation_script.sh https://pipeline-artifact-repository-service.eu-de.devops.cloud.ibm.com:443/v3/up.sh
if [ $? == 0 ]; then
export PIPELINE_CODESTATION_URL='https://pipeline-artifact-repository-service.eu-de.devops.cloud.ibm.com:443'
export PIPELINE_ARCHIVE_ID=''
export PIPELINE_ARCHIVE_TOKEN='567a99b070a1ac638802eeee35585b48.90b0777250225c7f81a466008180462a09199daf72eef76260d979f18ab00f51.a7c106a0157a64b3b4949ca25bd2d639afc706b6'
   sh _codestation_script.sh
else
   echo "An error occurred while attempting to download https://pipeline-artifact-repository-service.eu-de.devops.cloud.ibm.com:443/v3/up.sh"
   exit 1
fi
if [ "$PIPELINE_DEBUG_SCRIPT" == "true" ]; then
end_time=$(echo $(($(date +%s%N)/1000000)))
let "total_time=$end_time - $current_time"
echo "_DEBUG:UPLOAD_ARTIFACTS:$total_time"
current_time=
end_time=
total_time=
fi
fi
else
echo "Archive directory $ARCHIVE_DIR does not exist. Please check the name."
exit 1
fi
cd /
rm -rf $TMPDIR/*

EOF_POST_SCRIPT
source _post_script.sh
EOF_CUSTOMER_SCRIPT
if [ "$PIPELINE_DEBUG_SCRIPT" == "true" ]; then
current_time=$(echo $(($(date +%s%N)/1000000)))
fi
chmod +x ./_customer_script.sh
export PIPELINE_BASE_PROPS='ARCHIVE_DIR,BUILD_DISPLAY_NAME,BUILD_ID,BUILD_NUMBER,DIRECTORY_OFFSET,GIT_BRANCH,GIT_BRANCHES,GIT_COMMIT,GIT_COMMITS,GIT_PREVIOUS_COMMIT,GIT_PREVIOUS_COMMITS,GIT_URL,GIT_URLS,GIT_EVENT_PROVIDER,GIT_EVENT_TYPE,GIT_REQUEST_ACTION,GIT_REQUEST_URL,GIT_PR_TITLE,GIT_PR_NUMBER,BITBUCKET_PR_SOURCE_HOST,BITBUCKET_PR_SOURCE_BRANCH,IDS_JOB_ID,IDS_JOB_NAME,IDS_OUTPUT_PROPS,IDS_OUTPUT_TEXTAREA_PROPS,IDS_PROJECT_NAME,IDS_STAGE_NAME,IDS_URL,IDS_VERSION,JOB_NAME,PIPELINE_API_URL,PIPELINE_DEBUG_SCRIPT,PIPELINE_ID,PIPELINE_INITIAL_STAGE_EXECUTION_ID,PIPELINE_OWNER,PIPELINE_SCRIPTS_DIR,PIPELINE_STAGE_EXECUTION_ID,PIPELINE_STAGE_ID,PIPELINE_STAGE_INPUT_JOB_ID,PIPELINE_STAGE_INPUT_JOB_IDS,PIPELINE_STAGE_INPUT_REV,PIPELINE_STAGE_INPUT_REVS,PIPELINE_TOKEN,PIPELINE_TOOLCHAIN_ID,PIPELINE_TRIGGERING_USER,TASK_ID,TASK_TOKEN,TOOLCHAIN_TOKEN,WORKSPACE,PIPELINE_ARCHIVE_ID,PIPELINE_ARCHIVE_TOKEN,TOOLCHAIN_CRN,IBM_CLOUD_REGION,PIPELINE_BLUEMIX_API_KEY,PIPELINE_BLUEMIX_BSS_ACCOUNT_GUID,PIPELINE_BLUEMIX_RESOURCE_GROUP,PIPELINE_KUBERNETES_CLUSTER_NAME,PIPELINE_KUBERNETES_CLUSTER_ID,CF_APP,CF_CONFIG_JSON,CF_METADATA,CF_ORG,CF_ORGANIZATION_ID,CF_SCRIPT,CF_SPACE,CF_SPACE_ID,CF_TARGET_URL,CF_TOKEN,CF_USERNAME,CF_PASSWORD,PIPELINE_BLUEMIX_TARGET_URL,REGISTRY_URL,REGISTRY_NAMESPACE,IMAGE_NAME,IMAGE_TAG,PIPELINE_IMAGE_URL,EXT_GIT_BRANCH,EXT_GIT_URL,EXT_SCRIPT,EXT_AUTH_TOKEN,EXT_ID,PIPELINE_LOG_URL,PIPELINE_ARTIFACT_URL,PIPELINE_JOB_EXTENSION_ID'
unset DOCKER_VERSION DOCKER_CHANNEL DIND_COMMIT HOSTNAME
for i in $(echo $PIPELINE_BASE_PROPS,$IDS_OUTPUT_PROPS,$IDS_OUTPUT_TEXTAREA_PROPS | sed "s/,/ /g"); do [[ -v "$i" ]] && echo "$i=$(printenv $i | tr '\n' ' ' | rev | cut -c2- | rev)"; done > _env
DOCKER=/usr/local/bin/docker
DOCKER_IMAGE='travis-registry:5000/pipeline-worker:2.12'
DOCKER_LOGIN='true'
if [ ! -z "${DOCKER_USERNAME:=$DOCKER_USER}" ]; \
  then DOCKER_LOGIN="echo '$DOCKER_PASSWORD' | $DOCKER login -u '$DOCKER_USERNAME' --password-stdin" \
  && [[ "$DOCKER_IMAGE" == */* ]] && DOCKER_LOGIN="${DOCKER_LOGIN} '${DOCKER_IMAGE%%/*}'"; fi
DOCKER_PULL="echo Pulling pipeline base image latest ... && $DOCKER pull '$DOCKER_IMAGE' > /dev/null"
set +e
DEAMONPID=/var/run/docker.pid
while [[ ! -f "$DEAMONPID" ]];
do
sleep 1;
done;
set -e
DOCKER_RUN="$DOCKER run  --env-file='_env' -v $MOUNT_POINT:$MOUNT_POINT -w `pwd` --entrypoint='' '$DOCKER_IMAGE' ./_customer_script.sh"

sudo -- sh -c "sed -i '$ d' /etc/sudoers \
&& $DOCKER_LOGIN \
&& $DOCKER_PULL \
&& $DOCKER_RUN"

if [ "$PIPELINE_DEBUG_SCRIPT" == "true" ]; then
end_time=$(echo $(($(date +%s%N)/1000000)))
let "total_time=$end_time - $current_time"
echo "_DEBUG:USER_SCRIPT:$total_time"
current_time=
end_time=
total_time=
fi
