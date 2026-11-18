# salesforce-to-sql-integration

Enterprise Mule 4 application that incrementally extracts Salesforce Account records every 15 minutes and upserts them into PostgreSQL.

## Project structure

```text
salesforce-to-sql-integration/
|-- pom.xml
|-- mule-artifact.json
|-- README.md
|-- Jenkinsfile
|-- cloudhub-deployment.json
|-- src/
|   |-- main/
|   |   |-- mule/
|   |   |   |-- global-config.xml
|   |   |   `-- salesforce-account-sync.xml
|   |   `-- resources/
|   |       |-- config-dev.yaml
|   |       |-- config-qa.yaml
|   |       |-- config-prod.yaml
|   |       |-- secure.properties
|   |       |-- configuration-properties.xml
|   |       |-- log4j2.xml
|   |       |-- dw/
|   |       |   |-- transform-account.dwl
|   |       |   `-- validate-and-transform-account.dwl
|   |       `-- db/
|   |           `-- create-account-master.sql
|   `-- test/
|       `-- munit/
|           `-- salesforce-account-sync-test.xml
`-- target/ (generated build output)
```

## Prerequisites

- Mule 4.6 or later
- Java 17
- Maven 3.9 or later
- Anypoint Platform credentials
- PostgreSQL 12 or later
- Salesforce connected app with OAuth consumer credentials and API-enabled integration user

Create the PostgreSQL table:

```sql
psql "$DATABASE_URL" -f src/main/resources/db/create-account-master.sql
```

## Secure properties

This application uses Mule Secure Configuration Properties with AES/CBC. Generate the encrypted values using Anypoint Secure Properties Tool:

```text
{AES encrypted value}
```

Store the decrypted-at-runtime values in `src/main/resources/secure.properties` using:

```text
salesforce.username=![
  encrypted-value
]
```

Do not commit real credentials or the encryption key. Supply `mule.secure.key` and deploy-time secrets through runtime properties or a secrets manager.

Example runtime properties:

```text
env=prod
mule.secure.key=<32-character-or-more-secure-key>
```

For CloudHub, set the key as an application property and mark it as secure. The Salesforce and PostgreSQL values remain encrypted in `secure.properties`.

## Build and test

```powershell
mvn clean test
mvn clean package
```

The MUnit Maven plugin requires at least 85% application, resource, and flow coverage.

## Run locally

Set Java 17 and configure encrypted secrets:

```powershell
$env:MULE_SECURE_KEY="<secure-key>"
$env:env="dev"
mvn clean package
java -jar target/salesforce-to-sql-integration-1.0.0-mule-application.jar
```

The scheduler starts after the configured delay and then runs every 15 minutes.

## Runtime behavior

1. Retrieves `lastSuccessfulRunDate` from persistent Object Store.
2. Queries Salesforce for Accounts changed since the watermark.
3. Executes `AccountSyncBatch` in parallel batch records.
4. Transforms and upserts each record.
5. Updates the watermark only when the batch has zero failed records.
6. Logs totals and failures with correlation IDs.

The initial watermark is `2000-01-01T00:00:00Z`. Salesforce SOQL timestamps must use UTC format. Batch failures are retained for monitoring and do not advance the watermark.

## CloudHub deployment

Set CloudHub application properties:

```text
env=prod
mule.secure.key=<secure-key>
anypoint.platform.client_id=<API-manager-client-id>
anypoint.platform.client_secret=<API-manager-client-secret>
```

Deploy with Maven:

```powershell
mvn deploy -DmuleDeploy `
  -Denv=prod `
  -DapplicationName=salesforce-to-sql-integration `
  -Denvironment=Sandbox `
  -Dregion=us-east-1 `
  -DworkerType=MICRO `
  -Dworkers=1 `
  -Dregion=us-east-1 `
  -Danypoint.username="<username>" `
  -Danypoint.password="<password>" `
  -Dmule.secure.key="<secure-key>"
```

Alternatively, deploy from `cloudhub-deployment.json` through CI/CD.

## Runtime Fabric deployment

Build the artifact and publish it to Exchange or use Jenkins. Configure Runtime Fabric with Java 17 and Mule Runtime 4.6 or later. Supply environment variables or Runtime Fabric application properties for `env`, `mule.secure.key`, Salesforce secrets, and database network settings.

For Runtime Fabric, replace the internal host values in `config-prod.yaml` with resolvable Kubernetes or enterprise DNS names.
