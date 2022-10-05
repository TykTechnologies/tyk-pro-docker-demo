## Set these after bootstrapping a Tyk Dashboard Organization
TOKEN=2ba094237f1847ba4b3e2dea1c30f7c5    # User API Key / Token
ORG=633deab2f14d47000179304c              # Dashboard Org ID

## Defaults, can be left alone
CNAME=tyk-portal.localhost:3000           # (Optional) Portal CNAME you wish to set
DASH_URL=http://localhost:3000            # (Optional) This can be an IP, a hostname, etc, but Port is necessary if non-standard

# Create Portal.
curl -X POST $DASH_URL/api/portal/configuration \
  --header "Authorization: $TOKEN" \
  --data "{}"

# Initialize Catalogue.
curl -X POST $DASH_URL/api/portal/catalogue \
  --header "Authorization: $TOKEN" \
  --data "{
    \"org_id\": \"$ORG\"
  }"

# Create Portal Home Page.
curl -X POST $DASH_URL/api/portal/pages \
  --header "Authorization: $TOKEN" \
  --data "{
    \"is_homepage\": true,
    \"template_name\": \"\",
    \"title\": \"Developer Portal Home\",
    \"slug\": \"/\",
    \"fields\": {
      \"JumboCTATitle\": \"Tyk Developer Portal\",
      \"SubHeading\": \"Sub Header\",
      \"JumboCTALink\": \"#cta\",
      \"JumboCTALinkTitle\": \"Your awesome APIs, hosted with Tyk!\",
      \"PanelOneContent\": \"Panel 1 content.\",
      \"PanelOneLink\": \"#panel1\",
      \"PanelOneLinkTitle\": \"Panel 1 Button\",
      \"PanelOneTitle\": \"Panel 1 Title\",
      \"PanelThereeContent\": \"\",
      \"PanelThreeContent\": \"Panel 3 content.\",
      \"PanelThreeLink\": \"#panel3\",
      \"PanelThreeLinkTitle\": \"Panel 3 Button\",
      \"PanelThreeTitle\": \"Panel 3 Title\",
      \"PanelTwoContent\": \"Panel 2 content.\",
      \"PanelTwoLink\": \"#panel2\",
      \"PanelTwoLinkTitle\": \"Panel 2 Button\",
      \"PanelTwoTitle\": \"Panel 2 Title\"
    }
  }"

# Set Portal CNAME.
curl -X PUT $DASH_URL/api/portal/cname \
  --header "Authorization: $TOKEN" \
  --data "{
    \"cname\": \"$CNAME\"
  }"