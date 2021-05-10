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
