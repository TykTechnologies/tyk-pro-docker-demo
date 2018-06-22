#! /bin/bash

# This script will set up a full tyk environment on your machine
# and also create a demo user for you with one command

# USAGE
# -----
#
# $> ./setup.sh {IP ADDRESS OF DOCKER VM}

# OSX users will need to specify a virtual IP, linux users can use 127.0.0.1

# Tyk dashboard settings
TYK_DASHBOARD_USERNAME="test$RANDOM@test.com"
TYK_DASHBOARD_PASSWORD="test123"

# Tyk portal settings
TYK_PORTAL_DOMAIN="www.tyk-portal.com"
TYK_DASH_DOMAIN="www.tyk-dashboard.com"
TYK_PORTAL_PATH="/portal/"
ADMIN_KEY="12345"
ORG_NAME="TestOrg$RANDOM Ltd" 

DOCKER_IP="127.0.0.1"

function jsonKey {
    sed -n "s/.*\"${1}\":\"\([^\"]*\)\".*/\1/p"
}


function jsonDashboardResponse {
    sed -n "s/.*\"${1}\":\[\{.*\}\]/p"
}

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

ORGS_DATA=$(curl --silent --header "admin-auth: $ADMIN_KEY" --header "Content-Type:application/json" http://$DOCKER_IP:3000/admin/organisations 2>&1)
echo "ORGS_DATA: $ORGS_DATA"
HAS_ANOTHER_ORG=$(echo $ORGS_DATA |  python -c 'import json,sys;obj=json.load(sys.stdin);print obj["organisations"][0]["id"]')
if [ -n "$HAS_ANOTHER_ORG" ]
then
	echo "You have another organisation defined in mongoDB, would you like to proceed or stop in order to drop the database and then run this script again? "
	echo "Choose 'P' to add another oranisation or 'E' to exit $0 script"
	read ANSWER
	if [ $ANSWER = "P" ]
	then 
		echo "Will proceed with creating another organisation..."
	else
		echo "Running $0 script has stopped. Please drop the database and re-run this script"
		exit 5
	fi
fi

echo "Creating an Organisation..."
ORG_DATA=$(curl --silent --header "admin-auth: $ADMIN_KEY" --header "Content-Type:application/json" --data '{"owner_name": "TestOrg5 Ltd.","owner_slug": "testorg", "cname_enabled":true, "cname": "'$TYK_PORTAL_DOMAIN'"}' http://$DOCKER_IP:3000/admin/organisations 2>&1)
echo "ORG_DATA= $ORG_DATA"
STATUS_MESSAGE=$(echo $ORG_DATA | jsonKey "Status")
if [ "$STATUS_MESSAGE" != "OK" ]
then
	ERROR_MESSAGE=$(echo $ORG_DATA | jsonKey "Message")

	echo "The following error return from the API endpoint for creating an organisation: $ERROR_MESSAGE"

	if [ "$ERROR_MESSAGE" = "Failed to save new Org object to DB" ] 
	then
		echo "Please check MongoDB is running."
	fi
	echo "Running $0 script has stopped."
	exit 1
fi
ORG_ID=$(echo $ORG_DATA | jsonKey "Meta")
if [ -z "$ORG_ID" ]
then
	echo "Stopping $0 script - API call hasn't returned the org_id"
	exit 2
fi	
echo "    ORG ID: $ORG_ID"

echo "Adding a new user..."
USER_DATA=$(curl --silent --header "admin-auth: 12345" --header "Content-Type:application/json" --data '{"first_name": "John","last_name": "Smith","email_address": "'$TYK_DASHBOARD_USERNAME'","active": true,"org_id": "'$ORG_ID'"}' http://$DOCKER_IP:3000/admin/users 2>&1)
STATUS_MESSAGE=$(echo $USER_DATA | jsonKey "Status")
USER_AUTH=$(echo $USER_DATA | jsonKey "Message")
echo "    USER_AUTH= $USER_AUTH"
if [ "$STATUS_MESSAGE" != "OK" ]
then
	echo "The following error return from the API endpoint for creating a new user: $USER_AUTH"
	echo "Running $0 script has stopped."
	exit 3
fi
USER_LIST=$(curl --silent --header "authorization: $USER_AUTH" http://$DOCKER_IP:3000/api/users 2>&1)
STATUS_MESSAGE=$(echo $USER_LIST | jsonKey "Status")
if [ "$STATUS_MESSAGE" != "" ] && [ "$STATUS_MESSAGE" != "OK" ]
then
	ERROR_MESSAGE=$(echo $USER_LIST | jsonKey "Message")
        echo "    The following error return from the API endpoint for getting the user details: $ERROR_MESSAGE"
        echo "    Running $0 script has stopped."
        exit 3
fi
USER_ID=$(echo $USER_LIST | python -c 'import json,sys;obj=json.load(sys.stdin);print obj["users"][0]["id"]')
echo "USER ID: $USER_ID"
if [ -z $USER_ID ]
then
	echo "Failed to read the user we have just created"
	echo "    Running $0 script has stopped."
	exit 4
fi
echo "Setting password"
RESET_PASSWORD=$(curl --silent --header "authorization: $USER_AUTH" --header "Content-Type:application/json" http://$DOCKER_IP:3000/api/users/$USER_ID/actions/reset --data '{"new_password":"'$TYK_DASHBOARD_PASSWORD'"}')
STATUS_MESSAGE=$(echo $RESET_PASSWORD | jsonKey "Status")
if [ "$STATUS_MESSAGE" != "" ] && [ "$STATUS_MESSAGE" != "OK" ]
then
        ERROR_MESSAGE=$(echo $RESET_PASSWORD | jsonKey "Message")
        echo "    The following error was return by the API endpoint for reseting the user details: $ERROR_MESSAGE"
        echo "    Running $0 script has stopped."
        exit 3
fi

echo "Setting up the Portal catalogue"
CATALOGUE_DATA=$(curl --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data '{"org_id": "'$ORG_ID'"}' http://$DOCKER_IP:3000/api/portal/catalogue 2>&1)
CATALOGUE_STATUS=$(echo $CATALOGUE_DATA | jsonKey "Status")
if [ "$CATALOGUE_STATUS" != "" ] && [ "$CATALOGUE_STATUS" != "OK" ]
then
	ERROR_MESSAGE=$(echo $CATALOGUE_DATA | jsonKey "Message")
        echo "    The following error was return by the API endpoint for reseting the user details: $ERROR_MESSAGE"
        echo "    Running $0 script has stopped."
        exit 3
fi
OK=$(curl --silent --header "Authorization: $USER_AUTH" http://$DOCKER_IP:3000/api/portal/catalogue 2>&1)

echo "Creating the Portal Home page"
OK=$(curl --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data '{"is_homepage": true, "template_name":"", "title":"Tyk Developer Portal", "slug":"home", "fields": {"JumboCTATitle": "Tyk Developer Portal", "SubHeading": "Sub Header", "JumboCTALink": "#cta", "JumboCTALinkTitle": "Your awesome APIs, hosted with Tyk!", "PanelOneContent": "Panel 1 content.", "PanelOneLink": "#panel1", "PanelOneLinkTitle": "Panel 1 Button", "PanelOneTitle": "Panel 1 Title", "PanelThereeContent": "", "PanelThreeContent": "Panel 3 content.", "PanelThreeLink": "#panel3", "PanelThreeLinkTitle": "Panel 3 Button", "PanelThreeTitle": "Panel 3 Title", "PanelTwoContent": "Panel 2 content.", "PanelTwoLink": "#panel2", "PanelTwoLinkTitle": "Panel 2 Button", "PanelTwoTitle": "Panel 2 Title"}}' http://$DOCKER_IP:3000/api/portal/pages 2>&1)

echo "Fixing Portal URL"
URL_DATA=$(curl --silent --header "admin-auth: $ADMIN_KEY" --header "Content-Type:application/json" http://$DOCKER_IP:3000/admin/system/reload 2>&1)
CAT_DATA=$(curl -X POST --silent --header "Authorization: $USER_AUTH" --header "Content-Type:application/json" --data "{}" http://$DOCKER_IP:3000/api/portal/configuration 2>&1)

echo ""

echo "DONE"
echo "===="
echo "Login at http://$TYK_DASH_DOMAIN:3000/"
echo "Username: $TYK_DASHBOARD_USERNAME"
echo "Password: $TYK_DASHBOARD_PASSWORD"
echo "Portal: http://$TYK_PORTAL_DOMAIN:3000$TYK_PORTAL_PATH"
echo ""
