http = require 'http'
url = require 'url'
querystring = require 'querystring'
uuid = require 'node-uuid'
jade = require 'jade'

appConfig = require './config'
github = require './github'
db = require './db'
Client = db.Client
sequelize = db.sequelize

handler = require './handler'

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

#http router setup
useRoutes = (req, res, routes) ->
  for route in routes
    if not route.auth?
      console.log "#{route.pathname} does not require auth"
      route.auth = true
    if req.pathname is route.path and (route.auth or route.auth req)
      route.controller req, res
      return true
  return false

route = (req, res, router) ->
  routeFound = false
  for routes in router
    if useRoutes req, res, routes
      routeFound = true
      break
  if not routeFound
    res.statusCode = 404
    res.end 'no such location'

#http server setup
redirect_uri = url.parse(appConfig.redirectUri, true).pathname
server = http.createServer (req, res) ->
  parts = url.parse req.url, true
  query = parts.query
  req.queryObj = query
  req.pathname = parts.pathname

  console.log "visiting (%s) : %s", req.method, req.url

  router = []

  router.push require './admin-router'

  apiRoutes = []
  apiRoutes.push
    path: redirect_uri
    controller: (req, res) ->
      Client.findOne({
        where: {state: req.queryObj.state}
      }).then((client) ->
        github.request_token req.queryObj.code, (token_body) ->
          token_obj = querystring.parse token_body
          client.update({
            access_token: token_obj.access_token
          }).then(() ->
            res.end 'registered for repo: ' + client.repo
          )
      )

  apiRoutes.push
    path: '/api/listenpr'
    controller: (req, res) ->
      method = do req.method.toLowerCase
      if method is 'get' 
        listen_pullrequest[method] res, req.queryObj, req.body
      else
        req_body = ''
        req.on 'data', (ch) -> req_body += ch
        req.on 'end', () -> listen_pullrequest[method] res, req.queryObj, req_body

  router.push apiRoutes

  route req, res, router
  

server.listen appConfig.port
console.log "listening port: #{appConfig.port}"