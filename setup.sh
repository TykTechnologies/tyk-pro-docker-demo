#! /bin/bash

# This script will set up a full tyk environment on your machine
# and also create a demo user for you with one command

# USAGE
# -----
#
# $> ./setup.sh {IP ADDRESS OF DOCKER VM}

# OSX users will need to specify a virtual IP, linux users can use 127.0.0.1

if ! [ -x "$(command -v jq)" ]
then
  echo "Error: jq is not installed. It is required for this script."
  echo "Exit $0."
  echo ""
  exit 1
fi

# Tyk dashboard settings
RANDOM_ID=$RANDOM
TYK_DASHBOARD_USERNAME="test$RANDOM_ID@test.com"
TYK_DASHBOARD_PASSWORD="test123"

# Tyk portal settings
TYK_PORTAL_DOMAIN="www.tyk-portal-test.com"
TYK_DASH_DOMAIN="www.tyk-test.com"
TYK_PORTAL_PATH="/portal/"

ORG_NAME="TestOrg$RANDOM_ID.LTD"

DOCKER_IP="127.0.0.1"

if [ -n "$DOCKER_HOST" ]
then
    echo "Detected a Docker VM..."
    REMTCP=${DOCKER_HOST#tcp://}
    DOCKER_IP=${REMTCP%:*}
fi

if [ -n "$1" ]
then
    DOCKER_IP=$1
    echo "Docker host address explicitly set."
    echo "Using $DOCKER_IP as Tyk host address."
fi

if [ -n "$2" ]
then
    TYK_PORTAL_DOMAIN=$2
    echo "Docker portal domain address explicitly set."
    echo "Using $TYK_PORTAL_DOMAIN as Tyk host address."
fi

if [ -z "$1" ]
then
    echo "Using $DOCKER_IP as Tyk host address."
    echo "If this is wrong, please specify the instance IP address (e.g. ./setup.sh 192.168.1.1)"
fi

ORGS_DATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" http://$DOCKER_IP:3000/admin/organisations 2>&1)
if [ -z "$ORGS_DATA" ]
then
  echo "Get Organizations enpoint returned nothing. Please check the dashboard is running and start again."$
  echo "Running $0 script has stopped."
  echo ""
  exit 1
fi
STATUS_RESPONSE=$(echo $ORGS_DATA | jq '.Status')
if [ $STATUS_RESPONSE == '"Error"' ]
then
  MESSAGE_RESPONSE=$(echo $ORGS_DATA | jq '.Message')
  echo "Failed to get organizations list. Error: $MESSAGE_RESPONSE."$

  if [ "$MESSAGE_RESPONSE"  == '"Could not retrieve Organisations"' ]
  then
	  echo "Please check MongoDB is running."
  fi

  echo "Exit script $0."
  echo ""
  exit
fi
ORGS_LIST=$(echo $ORGS_DATA | jq  '.organisations')

# Handle multiple org creation
if [ "$ORGS_LIST" != "[]" ]
then$
    echo "IMPORTANT: You have already one or more organisations defined in mongoDB."
    echo "           Would you like to proceed and add another organisation or stop and drop the database and then run this script again? (y/n)"
  while true; do
    read -n 1 -p "Please enter just y/n: " ANSWER
      case $ANSWER in
       y ) echo -e "\nWill proceed with creating another organisation...";$
       break
       ;;
       n )  echo -e "\nExit script $0. "
	    echo -e "Please drop the database and re-run this script\n";$
	    exit
       ;;
       * )    echo -e "\n $ANSWER should be y/n...   "
       ;;
       esac
  done
fi

echo -e "Creating Organisation..."
ORG_DATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" --data '{"owner_name": "'$ORG_NAME'","owner_slug": "testorg", "cname_enabled":true, "cname": "'$TYK_PORTAL_DOMAIN'"}' http://$DOCKER_IP:3000/admin/organisations 2>&1)
STATUS_RESPONSE=$(echo $ORG_DATA | jq -r '.Status')
MESSAGE_RESPONSE=$(echo $ORG_DATA | jq '.Message')
if [ $STATUS_RESPONSE != "OK" ]
then
  echo "Failed to create organization. Returned error:" $MESSAGE_RESPONSE$
  echo -e "Exit script $0.\n"
  exit
fi

ORG_ID=$(echo $ORG_DATA | jq -r '.Meta')
if [ -z "$ORG_ID" ]
then
  echo "Stopping $0 script - API call hasn't returned the org_id"
  exit 3
fi


echo "Adding new user..."
USER_DATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" --data '{"first_name": "John","last_name": "Smith","email_address": "'$TYK_DASHBOARD_USERNAME'","active": true,"org_id": "'$ORG_ID'"}' http://$DOCKER_IP:3000/admin/users 2>&1)
echo "USER_DATA " $USER_DATA
STATUS_RESPONSE=$(echo $USER_DATA | jq '.Status')
if [ "$STATUS_RESPONSE" != '"OK"' ]
then
  MESSAGE_RESPONSE=$(echo $USER_DATA | jq '.Message')
  echo -e "\nFailed to create a user. Error: $MESSAGE_RESPONSE."$

  if [ "$MESSAGE_RESPONSE"  == '"Could not create API session for new user"' ]
  then
	  echo "Please check Redis is running."
  fi
  echo -e "Exit script $0. Please delete org " $ORG_ID " before starting again.\n"
  exit
fi
USER_AUTH=$(echo $USER_DATA | jq -r '.Message')
USER_LIST=$(curl --silent --header "authorization: $USER_AUTH" http://$DOCKER_IP:3000/api/users 2>&1)
IS_ERROR=$(echo $USER_LIST | jq -r .Status)
if [ "$IS_ERROR" != "null" ]
then
  MESSAGE_RESPONSE=$(echo $USER_LIST | jq -r '.Message')
  echo -e "\nFailed to get the users list. Returned error: $MESSAGE_RESPONSE."$
  echo -e "Exit script $0. Please delete org " $ORG_ID " before starting again.\n"
  exit
fi

USER_ID=$(echo $USER_LIST | jq  -r .users[0].id)
echo "USER AUTH: $USER_AUTH"
echo "USER ID: $USER_ID"

echo "Setting password..."
OK=$(curl --silent --header "authorization: $USER_AUTH" --header "Content-Type:application/json" http://$DOCKER_IP:3000/api/users/$USER_ID/actions/reset --data '{"new_password":"'$TYK_DASHBOARD_PASSWORD'"}')
IS_ERROR=$(echo $OK | jq -r .Status)
MESSAGE_RESPONSE=$(echo $OK | jq '.Message')
if [ "$IS_ERROR" == "Error" ]
then
  echo -e "\nFailed to get the users list. Returned error: $MESSAGE_RESPONSE "$
  echo -e "Exit script $0. Please delete org " $ORG_ID " before starting again.\n"
  exit
fi
echo "Reset password request: $MESSAGE_RESPONSE"

echo "Setting up the Portal catalogue..."
CATALOGUE_DATA=$(curl --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data '{"org_id": "'$ORG_ID'"}' http://$DOCKER_IP:3000/api/portal/catalogue 2>&1)
CATALOGUE_ID=$(echo $CATALOGUE_DATA | jq -r '.Message')
OK=$(curl --silent --header "Authorization: $USER_AUTH" http://$DOCKER_IP:3000/api/portal/catalogue 2>&1)

echo "Creating the Portal Home page..."
OK=$(curl --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data '{"is_homepage": true, "template_name":"", "title":"Tyk Developer Portal", "slug":"home", "fields": {"JumboCTATitle": "Tyk Developer Portal", "SubHeading": "Sub Header", "JumboCTALink": "#cta", "JumboCTALinkTitle": "Your awesome APIs, hosted with Tyk!", "PanelOneContent": "Panel 1 content.", "PanelOneLink": "#panel1", "PanelOneLinkTitle": "Panel 1 Button", "PanelOneTitle": "Panel 1 Title", "PanelThereeContent": "", "PanelThreeContent": "Panel 3 content.", "PanelThreeLink": "#panel3", "PanelThreeLinkTitle": "Panel 3 Button", "PanelThreeTitle": "Panel 3 Title", "PanelTwoContent": "Panel 2 content.", "PanelTwoLink": "#panel2", "PanelTwoLinkTitle": "Panel 2 Button", "PanelTwoTitle": "Panel 2 Title"}}' http://$DOCKER_IP:3000/api/portal/pages 2>&1)

echo "Fixing Portal URL"
URL_DATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" http://$DOCKER_IP:3000/admin/system/reload 2>&1)
CAT_DATA=$(curl -X POST --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data "{}" http://$DOCKER_IP:3000/api/portal/configuration 2>&1)

echo ""

echo "DONE"
echo "===="
echo "Organisation: $ORG_NAME"
echo "Organisation ID: $ORG_ID"
echo "Login at http://$TYK_DASH_DOMAIN:3000/"
echo "Username: $TYK_DASHBOARD_USERNAME"
echo "Password: $TYK_DASHBOARD_PASSWORD"
echo "Portal: http://$TYK_PORTAL_DOMAIN:3000$TYK_PORTAL_PATH"
echo ""
