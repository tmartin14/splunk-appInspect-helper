# splunk-appInspect-helper

This script will help in submitting Splunk Apps and Add-Ons to appInspect and for Splunk Cloud vetting.  This script will log in to Splunkbase to obtain a token that is then used to submit the App/Add-On to appInspect.  It will periodically check to see if the process has completed (once per minute) and when completed will retrieve the AppInspect results, save it into a file in the local directory and then open that file in a browser.   

More information on appInspect can be found on [dev.splunk.com](https://dev.splunk.com/enterprise/docs/releaseapps/appinspect/splunkappinspectapi/runappinspectrequestsapi)

## How to use this script:
```
./submit_appInspect.sh <TA_Filename>
```


## How this works:
### Login to Splunkbase to retreive your token for submissions: 

```
curl -X GET -u <splunkbase_id> --url "https://api.splunk.com/2.0/rest/login/splunk"
```

which results in the following response:
```json
{ 
    "status_code":200,
    "status":"success",
    "msg":"Successfully authenticated user and assigned a token",
    "data":{
        "token":"xxx",
        "user":{
            "name":"xxx",
            "email":"xxx@zzz.com",
            "username":"xxx",
            "groups":["xxxxx","yyyyy","zzzzz"]
        }
    }
}
```
### Submit an app/add-on to appInspect:

```
curl -X POST \
     -H "Authorization: bearer <token>" \
     -H "Cache-Control: no-cache" \
     -F "app_package=@\"<TA_Filename>\"" \
     --url "https://appinspect.splunk.com/v1/app/validate"
```
which results in the following response:
```json
{
    "request_id": "<request_id>",
    "message": "Validation request submitted.",
    "links": [
        {
            "rel": "status",
            "href": "/v1/app/validate/status/c<request_id>"
        },
        {
            "rel": "report",
            "href": "/v1/app/report/<request_id>"
        },
        {
            "rel": "package",
            "href": "/v1/app/package/<request_id>"
        }
    ]
}
```

### Check the status of a submission:

Once the App/Add-On has been submitted you can check the status using the status url above. 
```
curl -s -X GET \
         -H "Authorization: bearer <token>" \
         --url "https://appinspect.splunk.com/v1/app/validate/status/<request_id>"
```
which results in the following response:
```json
{   
    "request_id": "<request_id>", 
    "links": [ 
        { "href": "/v1/app/validate/status/<request_id>",  
          "rel": "self" 
        }, 
        { "href": "/v1/app/report/<request_id>", 
          "rel": "report" 
        } 
    ], 
    "status": "PROCESSING" 
}
```
### Request the report for a submission:

Once the process is complete (`status = SUCCESS|FAILURE|FAILED`) you can retrieve the results using the report url above. 
```
curl -s -X GET \
         -H "Authorization: bearer <token>" \
         --url "https://appinspect.splunk.com/v1/app/report/<request_id>"
```
The report is in HTML format.


## Additional Submissions
Similarlly you can submit a Splunk App or Add-On for Splunk cloud vetting.  The only difference is the addtion of the `included_tags=cloud` parameter used to submit the request.  The curl for cloud vetting is:
```
curl -s -X POST \
     -H "Authorization: bearer <token>" \
     -H "Cache-Control: no-cache" \
     -F "app_package=@\"<TA_Filename>\"" \
     -F "included_tags=cloud" \
     --url "https://appinspect.splunk.com/v1/app/validate"
```
Checking the status of the submission and retrieving the results are the same as appInspect above.