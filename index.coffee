http = require 'http'
https = require 'https'
fs = require 'fs'
url = require 'url'
querystring = require 'querystring'
uuid = require 'node-uuid'

port = process.env.PORT || 8080

app_config = {
	name: 'github-pr-checklist'
	client_id: '74ca93a65bffa081a74d'
	client_secret: '5e56b44128e1b02c382291baf36cb605a0fe6a02'
	redirect_uri: 'https://github-pr-checklist.herokuapp.com/oauth-callback'
}

#github-webhook-handler setup
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


		


#githubapi setup
githubAPI = require 'github'
github = new githubAPI {
	version: "3.0.0"
}

#github api
github_authorize = (res, client_id, redirect_uri, state) ->
	res.writeHead 302, {
		Location: 'https://github.com/login/oauth/authorize?client_id=' + client_id + '&redirect_uri=' + redirect_uri + '&scope=repo&state=' + state
	}
	do res.end

github_request_token = (client_id, client_secret, code, callback) ->
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
	token_req.write 'client_id=' + client_id + '&client_secret=' + client_secret + '&code=' + code
	do token_req.end


#api database
clients = []
pg = require 'pg'
Sequelize = require 'sequelize'
SequelizeMigration = require 'sequelize/'

sequelize = () ->
	_url = process.env.HEROKU_POSTGRESQL_CYAN_URL
	_host = _url.split('@')[1].split(':')[0]
	_port = _url.split('@')[1].split(':')[1].split('/')[0]
	new Sequelize _url, {
		dialect:  'postgres'
		protocol: 'postgres'
		port:     _port
		host:     _host
		logging:  true #false
		dialectOptions: { 
	        ssl: true
	    }
	}

Client = undefined
create_table = () ->
	_seq = sequelize()
	Client = _seq.define 'client', {
		state: Sequelize.STRING
		repo: Sequelize.STRING
		body: Sequelize.STRING(1024)
		access_token: Sequelize.STRING
	}
	do _seq.sync
do create_table


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
						github_authorize res, app_config.client_id, app_config.redirect_uri, random_state
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
		github_authorize res, app_config.client_id, app_config.redirect_uri
	else if pathname is '/oauth-callback'
		Client.findOne({
			where: {state: query.state}
		}).then((client) ->
			github_request_token app_config.client_id, app_config.client_secret, query.code, (token_body) ->
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
  

server.listen port
console.log 'server is listening'