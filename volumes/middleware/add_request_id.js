var addRequestIdMiddleware = new TykJS.TykMiddleware.NewMiddleware({});

addRequestIdMiddleware.NewProcessRequest(function(request, session) {
    log("Adding X-Request-Id request header (middleware)");

    // http://stackoverflow.com/questions/105034/create-guid-uuid-in-javascript
    var requestId = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
    log("X-Request-Id = " + requestId);

    request.SetHeaders["X-Request-Id"] = requestId;
    return addRequestIdMiddleware.ReturnData(request, {});
});

// Ensure init
log("Adding X-Request-Id header Middleware initialised");
