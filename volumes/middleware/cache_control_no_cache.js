var cacheControlNoCacheMiddleware = new TykJS.TykMiddleware.NewMiddleware({});

cacheControlNoCacheMiddleware.NewProcessRequest(function(request, session) {
    log("Process 'Cache-Control: no-cache' (middleware)");

    for(var i in request.Headers["Cache-Control"]) {
        if (request.Headers["Cache-Control"][i].toLowerCase() == "no-cache") {
            var cacheBust = (Math.random() * 1000000000).toString(16);
            request.AddParams["cache_bust"] = cacheBust;
            log("Found 'Cache-Control: no-cache', cache-bust: " + cacheBust);
            break;
        }
    }

    return cacheControlNoCacheMiddleware.ReturnData(request, {});
});

// Ensure init
log("Process 'Cache-Control: no-cache' initialised");
