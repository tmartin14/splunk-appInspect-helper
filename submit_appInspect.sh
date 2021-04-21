#!/bin/bash 

# Create your packaged app file
# COPYFILE_DISABLE=1 tar -cvzf <appname>.tar.gz <appname_directory>


# Did the user specify the file to submit?   If not , get it now
if [ $# -eq 0 ]; then
    read -p 'Enter the full path to the filename of the Splunk app to submit: ' APP_FILE_PATH 
  else
    APP_FILE_PATH="$1"
fi

### Check if the file exists, if not, exit ###
if [ ! -f "$APP_FILE_PATH" ]; then
    echo "ERROR:    $APP_FILE_PATH does not exist."
    echo
    echo "   Usage: ${0} <TA_Directory>"
    echo
    exit 9999 # die with error code 9999
fi

# Login to Splunkbase & get your token
read -p ' Enter your Splunkbase login: ' SPLUNKBASE_USER

RESPONSE=`curl -s -X GET -u "$SPLUNKBASE_USER" --url "https://api.splunk.com/2.0/rest/login/splunk" `
STATUS_CODE=`echo $RESPONSE | jq -r '.status_code'`
if [ $STATUS_CODE -ne 200 ]; then 
     echo $RESPONSE | jq -r '.msg' 
     exit 
fi
echo Successfully authenticated...
TOKEN=`echo $RESPONSE | jq -r '.data.token' `

# ----------------------------------------------------
#  Utlility Functions
# ----------------------------------------------------
# Retrieve the status of the a submission
# check_status( <token> <request_id>)
check_status(){
    RESPONSE=`curl -s -X GET \
         -H "Authorization: bearer $1" \
         --url "https://appinspect.splunk.com/v1/app/validate/status/$2" `
     echo $RESPONSE | jq -r .status 
     return `echo $RESPONSE | jq -r .status | grep -q 'SUCCESS\|FAILURE\|FAILED' `
}

# Retrieve report results  for a submission
# get_results( <token> <request_id> <output_filename>) 
get_results(){
     echo Retrieving Report...
     curl -s -X GET \
          -H "Authorization: bearer $1" \
          -H "Cache-Control: no-cache" \
          -H "Content-Type: text/html" \
         --url "https://appinspect.splunk.com/v1/app/report/$2" > "$3"
     open "$3"
}


# submit an application for appInspect
echo
echo Submitting AppInspect request...
RESPONSE=`curl -s -X POST \
     -H "Authorization: bearer $TOKEN" \
     -H "Cache-Control: no-cache" \
     -F "app_package=@\"$APP_FILE_PATH\"" \
     --url "https://appinspect.splunk.com/v1/app/validate" `
echo $RESPONSE
REQUEST_ID_VALIDATION=`echo "$RESPONSE" | jq -r '.request_id' `
#echo request_id="$REQUEST_ID_VALIDATION"
echo

# wait for the report to be ready
while ! check_status "$TOKEN" "$REQUEST_ID_VALIDATION"; do
     echo "Waiting for appInspect request to complete  $REQUEST_ID_VALIDATION ... this could take several minutes, checking status every 60 seconds"
     sleep 60
done

# get the report results  
get_results "$TOKEN" "$REQUEST_ID_VALIDATION" "appInspect_results.html") 

echo Done.
echo





: <<'END'
echo Retrieving appInspect Report...
curl -s -X GET \
     -H "Authorization: bearer $TOKEN" \
         -H "Cache-Control: no-cache" \
         -H "Content-Type: text/html" \
         --url "https://appinspect.splunk.com/v1/app/report/$REQUEST_ID_VALIDATION" > report1_appInspect.html
echo
echo


# submit review for Cloud Requirements
echo Submitting Cloud Validation request...
REQUEST_ID_CLOUD=`curl -s -X POST \
     -H "Authorization: bearer $TOKEN" \
     -H "Cache-Control: no-cache" \
     -F "app_package=@\"$APP_FILE_PATH\"" \
     -F "included_tags=cloud" \
     --url "https://appinspect.splunk.com/v1/app/validate" | jq -r '.request_id' `
echo request_id="$REQUEST_ID_CLOUD"
echo

# wait for the report to be ready
while ! check_status "$TOKEN" "$REQUEST_ID_VALIDATION"; do
echo "Waiting for appInspect request to complete  $REQUEST_ID_VALIDATION ... "
sleep 15
done

# get the report results  
curl -s -X GET \
     -H "Authorization: bearer $TOKEN" \
         -H "Cache-Control: no-cache" \
         -H "Content-Type: text/html" \
         --url "https://appinspect.splunk.com/v1/app/report/$REQUEST_ID_CLOUD" > report2_cloud.html

echo
echo

The python3 check is not needed if you are using all python3 code -- skipping this test

# submit review for compatibility with Python3
echo Submitting Python3 Validation request...
REQUEST_ID_PYTHON3=`curl -s -X POST \
     -H "Authorization: bearer $TOKEN" \
     -H "Cache-Control: no-cache" \
     -F "app_package=@\"$APP_FILE_PATH\"" \
     -F "included_tags=py3_migration" \
     --url "https://appinspect.splunk.com/v1/app/validate" | jq -r '.request_id' `
echo request_id="$REQUEST_ID_PYTHON3"
echo 

# wait for the report to be ready
while ! check_status $TOKEN $REQUEST_ID_PYTHON3; do
echo "Waiting for app validation request to complete  $REQUEST_ID_PYTHON3 ... "
sleep 15
done

# get the report results  
curl -s -X GET \
     -H "Authorization: bearer $TOKEN" \
         -H "Cache-Control: no-cache" \
         -H "Content-Type: text/html" \
         --url "https://appinspect.splunk.com/v1/app/report/$REQUEST_ID_PYTHON3" > report3_python3.html

END

echo Done.
echo
