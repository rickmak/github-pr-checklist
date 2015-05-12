config = {
  name: 'github-pr-checklist'
  clientID: '74ca93a65bffa081a74d'
  clientSecret: '5e56b44128e1b02c382291baf36cb605a0fe6a02'
  redirectUri: 'https://github-pr-checklist.herokuapp.com/oauth-callback'
  appSecret: 'set-it-yourself-and-this-is-supposed-to-be-highly-confidential'
  test: true
}

if process.env.DEPLOY
  config.test = false

if process.env.APP_SECRET
  config.appSecret = process.env.APP_SECRET

if process.env.GITHUB_CLIENT_ID
  config.clientID = process.env.GITHUB_CLIENT_ID

if process.env.GITHUB_SECRET
  config.clientSecret = process.env.GITHUB_SECRET

if process.env.GITHUB_REDIRECT_URI
  config.redirectUri = process.env.GITHUB_REDIRECT_URI

config.port = process.env.PORT || 8080

if process.env.DATABASE_URL
  config.db = {
    url: process.env.DATABASE_URL,
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
