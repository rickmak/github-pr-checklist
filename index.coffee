http = require 'http'
querystring = require 'querystring'
uuid = require 'node-uuid'

appConfig = require './config'
hander = require './handler'
github = require './github'
db = require './db'


clients = []

#api
listen_pullrequest = {
  ## should be "post" here...
  get: (res, params, body) ->
    random_state = do uuid.v1
    sequelize().sync().then () ->
      Client.count({where:{repo:params.repo}}).then((count) -> 
        if count == 0
          Client.create({
            state: random_state
            repo: params.repo
            body: params.body or ''
          }).then (() ->
            github.authorize res, random_state
          )
        else
          res.end 'repo registered'
      )     
  delete: (res, params, body) ->
    sequelize().sync().then () ->
      Client.destroy({where:{repo:params.repo},force:true}).then () ->
        res.end 'deleted: ' + params.repo
  patch: (res, params, body) ->
    console.log 'update body to: ', body
    sequelize().sync().then () ->
      Client.update({body: body}, {where:{repo: params.repo}}).then () ->
        res.end 'updated: ' + params.repo
}

#http server setup
server = http.createServer (req, res) ->
  parts = url.parse req.url, true
  query = parts.query
  pathname = parts.pathname
  method = do req.method.toLowerCase
  console.log "visiting (%s) : %s", req.method, req.url
  if pathname is '/test-oauth'
    github.authorize res
  else if pathname is '/oauth-callback'
    Client.findOne({
      where: {state: query.state}
    }).then((client) ->
      github.request_token query.code, (token_body) ->
        token_obj = querystring.parse token_body
        client.update({
          access_token: token_obj.access_token
        }).then(() ->
          res.end 'registered for repo: ' + client.repo
        )
    )
  else if pathname is '/api/listenpr'
    if method is 'get' 
      listen_pullrequest[method] res, query, req.body
    else
      req_body = ''
      req.on 'data', (ch) -> req_body += ch
      req.on 'end', () -> listen_pullrequest[method] res, query, req_body
  else if pathname is '/test/pull_request'
    matched_client = client for client in clients when client.repo is query.repo
    console.log matched_client
    res.end matched_client
  else if pathname is '/test/see_all_client'
    Client.findAll({
        
      }).then ((clients) ->
        resbody = ''
        for cl in clients
          resbody += 'cl.repo: ' + cl.repo + ',cl.body: ' + cl.body + ',cl.access_token: ' + cl.access_token + '\n'
        res.end resbody
      )
  else if pathname is '/test/reset'
    Client.destroy({where:{},force:true}).then () ->
      res.end 'deleted all records'
  else
    handler req, res, (err) ->
      res.statusCode = 404
      res.end 'no such location'
  

server.listen appConfig.port
console.log 'server is listening'
