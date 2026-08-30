#!/usr/local/bin/pwsh

if (Get-Content ./confs/tyk_analytics.env | sls TYK_DB_LICENSEKEY) {
    Write-Host "TYK_DB_LICENSEKEY exists in the file! Skipping.."
} else {
    $license_key = Read-Host -Prompt 'Please enter your Tyk Pro License key: '
    Write-Output "TYK_DB_LICENSEKEY=$license_key" >> ./confs/tyk_analytics.env
    Write-Output "PORTAL_LICENSEKEY=$license_key" >> ./confs/tyk_portal.env
}

Write-Host "Bringing Tyk Trial deployment UP..."
docker-compose up -d
if ($? -eq $False) {
    Write-Host "docker-compose up failed"
    exit
}

$status = ""
$desired_status = "200"
$attempt_count = 0
$attempt_max = 10

while (($status -ne $desired_status) -and ($attempt_count -le $attempt_max)) {
    $status = $(Invoke-WebRequest http://localhost:3000/hello | Select-Object -exp StatusCode)
    if ($attempt_count -eq $attempt_max) {
        Write-Host "    Attempt $attempt_count of $attempt_max unsuccessful, received '$status'"
    }
    $attempt_count += 1
    Start-Sleep -Seconds 1
}

Write-Host "Tyk configured. Bootstrapping environment..."

# Create default Org
$createOrgResponse = $(Invoke-WebRequest http://localhost:3000/admin/organisations/ `
                        -Method POST `
                        -Headers @{
                            "admin-auth" = "12345"
                            "Content-Type" = "application/json"
                        } `
                        -Body '{
                            "owner_name": "Tyk Demo",
                            "cname_enabled": true,
                            "event_options": {
                                "hashed_key_event": {
                                    "redis": true
                                },
                                "key_event": {
                                    "redis": true
                                }
                            },
                            "hybrid_enabled": true
                        }') | select-object -exp Content | ConvertFrom-Json

$orgId = $createOrgResponse.Meta
Write-Host "Created org"


# Create default user
$createUserResponse = $(Invoke-WebRequest 'http://localhost:3000/admin/users/' `
                        -Headers @{
                            "admin-auth" = "12345"
                            "Content-Type" = "application/json"
                        } `
                        -Method POST `
                        -Body @"
                            {
                                "org_id": "$orgId",
                                "first_name": "Dev",
                                "last_name": "Trial",
                                "email_address": "dev@tyk.io",
                                "active": true,
                                "user_permissions": { "IsAdmin": "admin" }
                            }
"@
                        ) | select-object -exp Content | ConvertFrom-Json
$user_id = $createUserResponse.Meta.id
$user_api_key = $createUserResponse.Meta.access_key
Write-Host "Created default user"

# Reset User Password
Invoke-WebRequest "http://localhost:3000/api/users/$user_id/actions/reset" `
    -Headers @{
        "authorization" = "$user_api_key"
        "Content-Type" = "application/json"
    } `
    -Method POST `
    -Body '{
        "new_password":"topsecret",
        "user_permissions": { "IsAdmin": "admin" }
    }' | Out-Null
Write-Host "Created user password"


# Creating API
$createApiResponse = $(Invoke-WebRequest 'http://localhost:3000/api/apis' `
    -Headers @{
        "authorization" = "$user_api_key"
        "Content-Type" = "application/json"
    } `
    -Method POST `
    -Body '{
        "api_definition": {
            "name": "Httpbin",
            "auth": {
                "auth_header_name": "authorization"
            },
            "definition": {
                "location": "header",
                "key": ""
            },
            "proxy": {
                "target_url": "http://echo.tyk-demo.com:8080/trial",
                "listen_path": "/httpbin"
            },
            "version_data": {
                "use_extended_paths": true,
                "not_versioned": true,
                "versions": {
                "Default": {
                    "expires": "",
                    "name": "Default",
                    "paths": {
                        "ignored": [],
                        "white_list": [],
                        "black_list": []
                    },
                    "use_extended_paths": false
                }
                }
            },
            "enable_ip_whitelisting": true,
            "active": true,
            "enable_batch_request_support": true
        }
    }') | select-object -exp Content | ConvertFrom-Json
$apiId = $createApiResponse.ID
Write-Host "Created Httpbin sample API"

# Create Policy
$createPolicyResponse = $(Invoke-WebRequest 'http://localhost:3000/api/portal/policies/' `
    -Method POST `
    -Headers @{
        "authorization" = "$user_api_key"
        "Content-Type" = "application/json"
    } `
    -Body @"
    {
        "access_rights": {
            "$apiId": {
                "allowed_urls": [],
                "api_id": "$apiId",
                "api_name": "Httpbin",
                "limit": null,
                "versions": [
                    "Default"
                ]
            }
        },
        "active": true,
        "name": "Default Security Policyy",
        "org_id": "$orgId",
        "per": 10,
        "rate": 2,
        "quota_max": -1,
        "quota_remaining": -1,
        "quota_renewal_rate": -1,
        "quota_renews": -1,
        "throttle_interval": -1,
        "throttle_retry_limit": -1,
        "tags": [],
        "allowance": 0,
        "auth_type": "other",
        "expires": 0,
        "key_expires_in": 0,
        "last_check": 0
    }
"@) | select-object -exp Content | ConvertFrom-Json

$policyId = $createPolicyResponse.Message
Write-Host "Created HttpBin Security Policy"

Start-Sleep -Seconds 4


# Create Httpbin API key
$keyName = "my_custom_key"
$createCustomKeyResponse = Invoke-WebRequest "http://localhost:3000/api/keys/$keyName" `
    -Method POST `
    -Headers @{
        "authorization" = "$user_api_key"
        "Content-Type" = "application/json"
    } `
    -Body @"
    {
        "apply_policies": [
            "$policyId"
        ],
        "org_id": "$orgId",
        "allowance": -1,
        "per": -1,
        "quota_max": -1,
        "rate": -1
    }
"@ | select-object -exp Content | ConvertFrom-Json

$key_id = $createCustomKeyResponse.key_id
Write-Host "Created Httpbin API Key"

# Send a setup ping
Invoke-WebRequest "http://localhost:8080/httpbin/anything/hello" -Headers @{ "Authorization" = $keyName }

Write-Host '
---------------------------
Please sign in at http://localhost:3000

user: dev@tyk.io
pw: topsecret

Your Tyk Gateway is found at http://localhost:8080

Press Enter to exit' -ForegroundColor Green

Read-Host