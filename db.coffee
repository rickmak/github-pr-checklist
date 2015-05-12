Sequelize = require 'sequelize'
config = require('./config').db

sequelize = () ->
  _url = config.url
  _host = _url.split('@')[1].split(':')[0]
  _port = _url.split('@')[1].split(':')[1].split('/')[0]
  new Sequelize _url, {
    dialect:  'postgres'
    protocol: 'postgres'
    port:     _port
    host:     _host
    logging:  config.logging
    dialectOptions: { 
      ssl: config.ssl
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

module.exports = {
  'Client': Client,
  'sequelize': sequelize
}
