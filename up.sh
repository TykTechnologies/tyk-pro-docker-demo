#!/bin/bash


read -n2048 -s -p 'Please enter your Tyk Pro License key: ' license_key
echo TYK_DB_LICENSEKEY=$license_key >> confs/tyk_analytics.env

echo "Bringing Tyk Trial deployment UP..."
docker-compose up -d

status=""
desired_status="200"
attempt_count=0
attempt_max=10

while [ "$status" != "$desired_status" ] && [ $attempt_count -le $attempt_max ]
do
    status=$(curl -s -o /dev/null -I -w "%{http_code}" http://localhost:3000/hello)

    if [ "$status" == "$desired_status" ]; then
        echo "    Attempt $attempt_count succeeded, received '$status'"
    elif [ $attempt_count -eq $attempt_max ]; then
        echo "    Attempt $attempt_count of $attempt_max unsuccessful, received '$status'"
    else
        echo "    Attempt $attempt_count unsuccessful, received '$status'"
    fi
    attempt_count=$((attempt_count + 1))
    sleep 1
done

tput setaf 2; echo "Tyk configured. Bootstrapping environment..."

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

echo '
---------------------------
Please sign in at http://localhost:3000

user: dev@tyk.io
pw: topsecret
'