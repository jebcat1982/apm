path = require 'path'
CSON = require 'season'
fs = require 'fs-plus'
temp = require 'temp'
express = require 'express'
http = require 'http'
wrench = require 'wrench'
apm = require '../lib/apm-cli'

describe 'apm rebuild', ->
  [server] = []

  beforeEach ->
    spyOnToken()
    silenceOutput()

    app = express()
    app.get '/node/v0.12.0/node-v0.12.0.tar.gz', (request, response) ->
      response.sendfile path.join(__dirname, 'fixtures', 'node-v0.12.0.tar.gz')
    app.get '/node/v0.12.0/node.lib', (request, response) ->
      response.sendfile path.join(__dirname, 'fixtures', 'node.lib')
    app.get '/node/v0.12.0/x64/node.lib', (request, response) ->
      response.sendfile path.join(__dirname, 'fixtures', 'node_x64.lib')
    app.get '/node/v0.12.0/SHASUMS256.txt', (request, response) ->
      response.sendfile path.join(__dirname, 'fixtures', 'SHASUMS256.txt')

    server =  http.createServer(app)
    server.listen(3000)

    atomHome = temp.mkdirSync('apm-home-dir-')
    process.env.ATOM_HOME = atomHome
    process.env.ATOM_ELECTRON_URL = "http://localhost:3000/node"
    process.env.ATOM_PACKAGES_URL = "http://localhost:3000/packages"
    process.env.ATOM_ELECTRON_VERSION = 'v3.3.0'
    process.env.ATOM_RESOURCE_PATH = temp.mkdirSync('atom-resource-path-')

  afterEach ->
    server.close()

  it "rebuilds all modules when no module names are specified", ->
    packageToRebuild = temp.mkdirSync('apm-test-package-')
    fs.writeFileSync(path.join(packageToRebuild, 'package.json'), JSON.stringify(name: 'test', version: '1.0.0'))
    process.chdir(packageToRebuild)
    callback = jasmine.createSpy('callback')
    apm.run(['rebuild'], callback)

    waitsFor 'waiting for rebuild to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0]).toBeUndefined()

  it "rebuilds the specified modules", ->
    packageToRebuild = temp.mkdirSync('apm-test-package-')
    fs.writeFileSync(path.join(packageToRebuild, 'package.json'), JSON.stringify(name: 'test', version: '1.0.0'))
    process.chdir(packageToRebuild)
    callback = jasmine.createSpy('callback')
    apm.run(['rebuild', 'foo'], callback)

    waitsFor 'waiting for rebuild to complete', 600000, ->
      callback.callCount is 1

    runs ->
      expect(callback.mostRecentCall.args[0]).toBeUndefined()
