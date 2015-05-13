appConfig = require './config'
db = require './db'
Client = db.Client
jade = require 'jade'


adminAuth = (req) -> 
  console.log "secret: #{req.queryObj.secret}"
  req.queryObj.secret? and req.queryObj.secret is appConfig.appSecret

routes = []

routes.push
  path: '/admin/checklist'
  auth: adminAuth
  controller: (req, res) ->
    where = {}
    if req.queryObj.repo? then where.repo = req.queryObj.repo
    Client.findAll({where:where}).then ((clients) ->
        res.end jade.renderFile 'views/prlist.jade', 
          registered: clients
    )

routes.push
  path: '/admin/delete'
  auth: adminAuth
  controller: (req, res) ->
    do (req, res) =>
      where = {}
      if req.queryObj.repo? then where.repo = req.queryObj.repo
      Client.destroy({where:where,force:true}).then () ->
        if req.queryObj.repo? 
          res.end "deleted #{req.queryObj.repo}"
        else
          res.end 'deleted all records'


module.exports = routes