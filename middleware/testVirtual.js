function myUniqueFunctionName(request, session, config) {
    var responseObject = { 
      Body: "THIS IS A  VIRTUAL RESPONSE", 
      Code: 200 
    }
    return TykJsResponse(responseObject, session.meta_data)
  }