#!/bin/bash 

# Create your packaged app file
# COPYFILE_DISABLE=1 tar -cvzf <appname>.tar.gz <appname_directory>


# Did the user specify the file to submit?   If not , get it now
if [ $# -eq 0 ]; then
    read -p 'Enter the full path to the filename of the Splunk app to submit: ' APP_FILE_PATH 
  else
    APP_FILE_PATH="$1"
    echo "$APP_FILE_PATH"
fi

### Check if the file exists, if not, exit ###
if [ ! -f "$APP_FILE_PATH" ]; then
    echo "ERROR:    $APP_FILE_PATH does not exist."
    echo "   Usage:    ./convert.sh TA_Directory"
    echo
    exit 9999 # die with error code 9999
fi

read -p 'Enter the Splunkbase user id to use: ' SPLUNKBASE_USER


# 1. Login to Splunkbase & get your token
echo Lets get your TOKEN from Splunkbase...
TOKEN=`curl -s -X GET -u "$SPLUNKBASE_USER" --url "https://api.splunk.com/2.0/rest/login/splunk" | jq -r '.data.token' `

# 2.  submit an application for validation
echo Submitting AppInspect request...
REQUEST_ID_VALIDATION=`curl -s -X POST \
     -H "Authorization: bearer $TOKEN" \
     -H "Cache-Control: no-cache" \
     -F "app_package=@\"$APP_FILE_PATH\"" \
     --url "https://appinspect.splunk.com/v1/app/validate" | jq -r '.request_id' `
echo request_id=$REQUEST_ID_VALIDATION


# 3.  submit review for Cloud Requirements
echo Submitting Cloud Validation request...
REQUEST_ID_CLOUD=`curl -s -X POST \
     -H "Authorization: bearer $TOKEN" \
     -H "Cache-Control: no-cache" \
     -F "app_package=@\"$APP_FILE_PATH\"" \
     -F "included_tags=cloud" \
     --url "https://appinspect.splunk.com/v1/app/validate" | jq -r '.request_id' `
echo request_id=$REQUEST_ID_CLOUD


# 4.  submit review for compatibility with Python3
echo Submitting Python3 Validation request...
REQUEST_ID_PYTHON3=`curl -s -X POST \
     -H "Authorization: bearer $TOKEN" \
     -H "Cache-Control: no-cache" \
     -F "app_package=@\"$APP_FILE_PATH\"" \
     -F "included_tags=py3_migration" \
     --url "https://appinspect.splunk.com/v1/app/validate" | jq -r '.request_id' `
echo request_id=$REQUEST_ID_PYTHON3



# 5.  Retrieve the status of the validation
check_status(){
    curl -s -X GET \
         -H "Authorization: bearer $1" \
         --url "https://appinspect.splunk.com/v1/app/validate/status/$2" | jq -r .status | grep -q 'SUCCESS\|FAILURE\|FAILED'
}

while ! check_status $TOKEN $REQUEST_ID_VALIDATION; do
echo Waiting for app validation request to complete  $REQUEST_ID_VALIDATION ... 
sleep 15
done

while ! check_status $TOKEN $REQUEST_ID_CLOUD; do
echo Waiting for cloud validation request to complete  $REQUEST_ID_CLOUD ... 
sleep 15
done

while ! check_status $TOKEN $REQUEST_ID_PYTHON3; do
echo Waiting for app validation request to complete  $REQUEST_ID_PYTHON3 ... 
sleep 15
done

# 6.Get the report results   (one for each request ID above)
echo Retrieving Reports...
curl -s -X GET \
     -H "Authorization: bearer $TOKEN" \
         -H "Cache-Control: no-cache" \
         -H "Content-Type: text/html" \
         --url "https://appinspect.splunk.com/v1/app/report/$REQUEST_ID_VALIDATION" > report1_appInspect.html

curl -s -X GET \
     -H "Authorization: bearer $TOKEN" \
         -H "Cache-Control: no-cache" \
         -H "Content-Type: text/html" \
         --url "https://appinspect.splunk.com/v1/app/report/$REQUEST_ID_CLOUD" > report2_cloud.html

curl -s -X GET \
     -H "Authorization: bearer $TOKEN" \
         -H "Cache-Control: no-cache" \
         -H "Content-Type: text/html" \
         --url "https://appinspect.splunk.com/v1/app/report/$REQUEST_ID_PYTHON3" > report3_python3.html

echo Done.





