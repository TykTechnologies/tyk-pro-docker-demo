## Adding JavasScript Middleware ##

This directory contains JavaScript Middleware examples. They are used by adding them to an API Definition in the "custom_middleware" section. At present, this cannot be preformed from the dashboard, so after creating an API:

- Export the API definition
- Modify the "custom_middleware" section, i.e.:
```

    "custom_middleware": {
        "pre": [
            {
                "name": "addRequestIdMiddleware",
                "path": "/opt/tyk-gateway/middleware/add_request_id.js",
                "require_session": false
            }

        ],
```
- Delete the existing API Definition
- Copy the API Defintion
- Import the modified API Definition by pasting the definition into the Import dialog box.

There are also other ways to load custom JavaScript middleware. See the documentation on-line.
