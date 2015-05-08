https = require 'https'

config = require './config'

#github api
authorize = (res, state) ->
  res.writeHead 302, {
    Location: 'https://github.com/login/oauth/authorize?client_id=' + config.clientId + '&redirect_uri=' + config.redirectUri + '&scope=repo&state=' + state
  }
  do res.end

request_token = (code, callback) ->
  options = {
    hostname: 'github.com'
    path: '/login/oauth/access_token'
    method: 'POST'
  }
  token_req = https.request options, (token_res) ->
    console.log 'Status: ', token_res.statusCode
    console.log 'Headers: ', JSON.stringify(token_res.headers)
    token_res.setEncoding 'utf8'
    body = ''
    token_res.on 'data', (chunk) ->
      body += chunk
    token_res.on 'end', () ->
      # res.end body
      console.log body 
      callback body
  token_req.on 'error', (err) ->
    console.log 'problem with request: ', e.message
  token_req.write 'client_id=' + config.clientId + '&client_secret=' + config.clientSecret  + '&code=' + code
  do token_req.end


module.exports = {
  'authorize': authorize,
  'request_token': request_token
}
