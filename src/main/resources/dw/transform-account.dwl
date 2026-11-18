%dw 2.0
output application/java
---
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
