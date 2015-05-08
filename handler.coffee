https = require 'https'

createHandler = require 'github-webhook-handler'
handler = createHandler {
  path: '/github-web-hook'
  secret: 'oursky'
}

handler.on 'error', (err) ->
  console.error 'Error: ', err.message

handler.on 'push', (event) ->
  console.log 'Received a push event for %s to %s', event.payload.repository.name, event.payload.ref

handler.on 'pull_request', (event) ->
  console.log 'Received a pull request on %s', event.payload.repository.full_name
  if event.payload.action is 'opened'
    # matched_client = client for client in clients when client.repo is event.payload.repository.full_name
    Client.findOne({
      where: {repo: event.payload.repository.full_name}
    }).then((matched_client) ->
      options = {
        hostname: 'api.github.com'
        path: '/repos/' + matched_client.repo + '/pulls/' + event.payload.number
        method: 'PATCH'
        headers: {
          'User-Agent': app_config.name
          'Authorization': 'token ' + matched_client.access_token
        }
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
      token_req.on 'error', (err) ->
        console.log 'problem with request: ', e.message
      token_req.write JSON.stringify({
        title: event.payload.pull_request.title
        body: event.payload.pull_request.body + '\n' + matched_client.body
        state: event.payload.pull_request.state
        })
      do token_req.end
    )

module.exports = handler
