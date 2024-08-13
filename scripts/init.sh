#!/bin/bash

# Path to the .env file
env_file=".env"

# Check if the .env file exists
if [ -f "$env_file" ]; then
    echo ".env file already exists. Skipping creation."
else
    # The .env file does not exist, create it and prompt for the license key
    echo "Creating .env file..."
    touch "$env_file"

    read -n2048 -s -p 'Please enter your Tyk Pro License key: ' license_key
    echo

    echo "DASH_LICENSE=$license_key" >> "$env_file"
    echo ".env file created and keys added."
fi

echo "Bringing Tyk Trial deployment UP..."
docker-compose up -d
if [ $? -ne 0 ]; then
    echo "docker-compose up failed"
    exit 1
fi

status=""
desired_status="200"
attempt_count=0
attempt_max=10

while [ "$status" != "$desired_status" ] && [ $attempt_count -le $attempt_max ]
do
    status=$(curl -s -o /dev/null -I -w "%{http_code}" http://localhost:3000/hello)

    if [ $attempt_count -eq $attempt_max ]; then
        echo "    Attempt $attempt_count of $attempt_max unsuccessful, received '$status'"
    fi
    attempt_count=$((attempt_count + 1))
    sleep 1
done

echo "Tyk configured. Bootstrapping environment..."

# Create default Org
createOrgResponse=$(curl -s --location 'http://localhost:3000/admin/organisations/' \
                        --header 'admin-auth: 12345' \
                        --header 'Content-Type: application/json' \
                        --data '{
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
                        }')

orgId=$(echo "$createOrgResponse" | awk -F'"' '/"Meta":/{print $(NF-1)}')
echo "Created org"


# Create default user
createUserResponse=$(curl -s --location 'http://localhost:3000/admin/users/' \
--header 'Content-Type: application/json' \
--header 'admin-auth: 12345' \
--data-raw '{
  "org_id": "'$orgId'",
  "first_name": "Dev",
  "last_name": "Trial",
  "email_address": "dev@tyk.io",
  "active": true,
  "user_permissions": { "IsAdmin": "admin" }
}')
user_id=$(echo "$createUserResponse" | awk -F'"id":"' '{split($2,a,"\""); print a[1]}')
user_api_key=$(echo "$createUserResponse" | awk -F'"access_key":"' '{split($2,a,"\""); print a[1]}')
echo "Created default user"

# Reset User Password
curl -s -o /dev/null --location 'http://localhost:3000/api/users/'$user_id'/actions/reset' \
--header 'Content-Type: application/json' \
--header 'authorization: '$user_api_key \
--data '{
  "new_password":"topsecret",
  "user_permissions": { "IsAdmin": "admin" }
}'
echo "Created user password"


# Creating API
createApiResponse=$(curl -s --location 'http://localhost:3000/api/apis' \
--header 'authorization: '$user_api_key'' \
--header 'Content-Type: application/json' \
--data '{
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
          "listen_path": "/httpbin",
          "strip_listen_path": true
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
}')
apiId=$(echo "$createApiResponse" | awk -F'"' '/"ID":/{print $(NF-1)}')
echo "Created Httpbin sample API"

# Create Policy
createPolicyResponse=$(curl -s --location 'localhost:3000/api/portal/policies/' \
--header 'Authorization: '$user_api_key'' \
--header 'Content-Type: application/json' \
--data '{
    "access_rights": {
        "'$apiId'": {
            "allowed_urls": [],
            "api_id": "'$apiId'",
            "api_name": "Httpbin",
            "limit": null,
            "versions": [
                "Default"
            ]
        }
    },
    "active": true,
    "name": "Default Security Policyy",
    "org_id": "'$orgId'",
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
}')

policyId=$(echo "$createPolicyResponse" | grep -o '"Message":"[^"]*"' | cut -d":" -f2 | tr -d '"')
echo "Created HttpBin Security Policy"


sleep 4

# Create Httpbin API key
keyName=my_custom_key
curl -s -o /dev/null --location 'localhost:3000/api/keys/'$keyName \
--header 'authorization: '$user_api_key'' \
--header 'Content-Type: application/json' \
--data-raw '{
     "apply_policies": [
         "'$policyId'"
     ],
    "org_id": "'$orgId'",
    "allowance": -1,
    "per": -1,
    "quota_max": -1,
    "rate": -1
}'
echo "Created Httpbin API Key"

# Send a setup ping
curl -s -o /dev/null http://localhost:8080/httpbin/anything/hello -H "Authorization: my_custom_key"

tput setaf 2;
echo '
---------------------------
Please sign in at http://localhost:3000

user: dev@tyk.io
pw: topsecret

Your Tyk Gateway is found at http://localhost:8080

Press Enter to exit'

read
