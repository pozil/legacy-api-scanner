# Legacy API Scanner

Run this anonymous Apex code to to identify if your Salesforce org is receiving legacy SOAP, REST or Bulk API calls as defined in this [knowledge article](https://help.salesforce.com/articleView?id=000351312&type=1&mode=1&language=en_US).

The scanner inspects the `ApiTotalUsage` event logs and lists outdated API calls with their API type and versions.

**ℹ️&nbsp;&nbsp;Disclaimers:**

- this tool is not officialy supported by Salesforce and is provided as-is without any warranties.
- never execute anonymous Apex code that you don't trust or understand against your org. Consider reading the ~90 lines of [legacy-api-scanner.apex](legacy-api-scanner.apex).
- depending on your org's activity, you may experience `System.LimitException` errors. These are due to large log files that Apex can't process. In that case, fall back to manual log inspection with the REST API as documented in this [knowledge article](https://help.salesforce.com/articleView?id=000351312&type=1&mode=1&language=en_US)

## Instructions

1. Clone this repository and navigate to the project folder:

   ```sh
   git clone git@github.com:pozil/legacy-api-scanner.git
   cd legacy-api-scanner
   ```

1. Run the anonymous Apex code to run a scan with the Salesforce CLI:

   ```apex
   sfdx force:apex:execute -f legacy-api-scanner.apex -u <YOUR_USERNAME>
   ```

1. Inspect the Apex debug logs

   If you have legacy API calls in your org's logs, you will see this kind of output:

   > Found legacy API versions in logs: {SOAP v7, REST v20, BULK_AP v21}

   If that's the case, continue your investigations manually as indicated in this [knowledge article](https://help.salesforce.com/articleView?id=000351312&type=1&mode=1&language=en_US).

   Otherwise, you will see this message:

   > Found no EventLogFile entry of type ApiTotalUsage.<br/>
   > This indicates that no legacy APIs were called during the log retention window.

   This means that there could still be some legacy API calls made against your org, but they are outside of the log retention window.

   > API enabled organizations have free access to the API Total Usage event log files with 1-day data retention. For an extra cost, you can access this and all other log file types with 30-day data retention.
