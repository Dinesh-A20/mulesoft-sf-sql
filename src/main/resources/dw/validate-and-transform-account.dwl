%dw 2.0
output application/java
var validRecord = payload.Id != null and payload.Name != null
---
if (validRecord)
    {
        ACCOUNT_ID: payload.Id,
        ACCOUNT_NAME: payload.Name,
        ACCOUNT_TYPE: payload."Type",
        INDUSTRY: payload.Industry,
        PHONE: payload.Phone,
        WEBSITE: payload.Website,
        BILLING_CITY: payload.BillingCity,
        BILLING_COUNTRY: payload.BillingCountry,
        LAST_MODIFIED: payload.LastModifiedDate
    }
else
    fail "Invalid Salesforce Account record: Id and Name are required"
