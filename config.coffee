config = {
  name: 'github-pr-checklist'
  client_id: '74ca93a65bffa081a74d'
  client_secret: '5e56b44128e1b02c382291baf36cb605a0fe6a02'
  redirect_uri: 'https://github-pr-checklist.herokuapp.com/oauth-callback'
}

config['port'] = process.env.PORT || 8080

if process.env.HEROKU_POSTGRESQL_CYAN_URL
  config.db = {
    url: process.env.HEROKU_POSTGRESQL_CYAN_URL,
    ssl: true,
    logging: false
  }
else
  config.db = {
    url: "postgres://github-pr-checklist@localhost:5432/github-pr-checklist",
    ssl: false,
    logging: true
  }

module.exports = config
