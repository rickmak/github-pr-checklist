appConfig = require './config'
db = require './db'
Client = db.Client
jade = require 'jade'


auth = (req) -> req.queryObj.secret? and req.queryObj.secret is appConfig.appSecret

routes = []

routes.push
  path: '/admin/checklist'
  auth: auth
  controller: (req, res) ->
    where = {}
    if req.queryObj.repo? then where.repo = req.queryObj.repo
    Client.findAll({where:where}).then ((clients) ->
        res.end jade.renderFile 'views/prlist.jade', 
          registered: clients
    )

routes.push
  path: '/admin/delete'
  auth: auth
  controller: (req, res) ->
    where = {}
    if req.queryObj.repo? then where.repo = req.queryObj.repo
    Client.destroy({where:where,force:true}).then () ->
      res.end 'deleted all records'


module.exports = routes