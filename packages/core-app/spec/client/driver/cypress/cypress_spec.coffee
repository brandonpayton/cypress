describe "$Cypress API", ->
  beforeEach ->
    ## back these up!
    @modules = $Cypress.modules

    $Cypress.reset()
    @Cypress = $Cypress.create()

  afterEach ->
    $Cypress.modules = @modules
    @Cypress.stop()

  it ".modules", ->
    expect($Cypress.modules).to.deep.eq {}

  it ".register", ->
    fn = ->
    $Cypress.register "foo", fn
    expect($Cypress.modules.foo).to.eq fn

  it ".remove", ->
    $Cypress.register "foo", ->
    $Cypress.remove "foo"
    expect($Cypress.modules).to.deep.eq {}

  it ".extend", ->
    $Cypress.extend {foo: -> "foo"}
    expect(@Cypress.foo()).to.eq "foo"
    delete $Cypress.prototype.foo

  describe ".create", ->
    it "returns new Cypress instance", ->
      expect(@Cypress).to.be.instanceof $Cypress

    it "attaches klasses to instance", ->
      klasses = "Cy Log Utils Chai Mocha Runner Agents Server Chainer Location LocalStorage".split(" ")
      for klass in klasses
        expect(@Cypress[klass]).to.eq $Cypress[klass]

  describe "#constructor", ->
    it "nulls cy, chai, mocha, runner", ->
      _.each ["cy", "chai", "mocha", "runner"], (prop) =>
        expect(@Cypress[prop]).to.be.null

    it "sets Cypress on the window", ->
      @Cypress.stop().then ->
        expect(window.Cypress).to.be.undefined
        Cypress = $Cypress.create()
        Cypress.start()
        expect(window.Cypress).to.eq Cypress

  describe "#loadModule", ->
    it "invokes module callback", (done) ->
      $Cypress.register "SomeCommand", (Cypress, _, $) =>
        expect(Cypress).to.eq @Cypress
        expect(_).to.be.ok
        expect($).to.be.ok
        done()

      @Cypress.loadModule "SomeCommand"

    it "throws when no module is found by name", ->
      fn = => @Cypress.loadModule("foo")

      expect(fn).to.throw "$Cypress.Module: foo not registered."

  describe "#loadModules", ->
    beforeEach ->
      @loadModule = @sandbox.stub @Cypress, "loadModule"

    it "can loads modules by array of names", ->
      @Cypress.loadModules ["foo", "bar", "baz"]
      expect(@loadModule.firstCall).to.be.calledWith "foo"
      expect(@loadModule.secondCall).to.be.calledWith "bar"
      expect(@loadModule.thirdCall).to.be.calledWith "baz"

    it "can automatically load all modules", ->
      $Cypress.register "foo", ->
      $Cypress.register "bar", ->
      $Cypress.register "baz", ->
      @Cypress.loadModules()
      expect(@loadModule.firstCall).to.be.calledWith "foo"
      expect(@loadModule.secondCall).to.be.calledWith "bar"
      expect(@loadModule.thirdCall).to.be.calledWith "baz"

  describe "#stop", ->
    it "calls .abort()", ->
      abort = @sandbox.spy(@Cypress, "abort")
      @Cypress.stop().then ->
        expect(abort).to.be.called

    it "triggers stop", ->
      trigger = @sandbox.spy(@Cypress, "trigger")
      @Cypress.stop().then ->
        expect(trigger).to.be.calledWith "stop"

    it "unbinds all listeners", ->
      @Cypress.on "foo", ->
      expect(@Cypress._events).not.to.be.empty

      offFn = @sandbox.spy(@Cypress, "off")
      @Cypress.stop().then =>
        expect(offFn).to.be.calledOnce
        expect(@Cypress._events).to.be.empty

    it "deletes Cypress from the window", ->
      @Cypress.stop().then ->
        expect(window.Cypress).to.be.undefined

  describe "#abort", ->
    it "waits for all aborts to resolve", (done) ->
      aborted = false

      @Cypress.on "abort", ->
        Promise.resolve().then ->
          aborted = true

      @Cypress.abort().then ->
        expect(aborted).to.be.true
        done()

    it "calls #restore", ->
      restore = @sandbox.spy @Cypress, "restore"

      @Cypress.abort().then ->
        expect(restore).to.be.calledOnce

  describe "#initialize", ->
    beforeEach ->
      @trigger = @sandbox.spy @Cypress, "trigger"

      @Cypress.runner = {}
      @Cypress.mocha = {options: @sandbox.spy()}
      @Cypress.initialize(1,2)

    it "triggers 'initialize'", ->
      expect(@trigger).to.be.calledWith "initialize", {
        specWindow: 1
        $remoteIframe: 2
      }

    it "calls mocha#options with runner", ->
      expect(@Cypress.mocha.options).to.be.calledWith {}

  describe "#run", ->
    it "throws when no runner", ->
      @Cypress.runner = null
      expect(=> @Cypress.run()).to.throw "Cannot call Cypress#run without a runner instance."

    it "passes the function to the runner#run", ->
      @fn = ->
      @Cypress.runner = { run: @sandbox.spy() }
      @Cypress.run @fn
      expect(@Cypress.runner.run).to.be.calledWith @fn

  describe "#env", ->
    beforeEach ->
      @Cypress.setConfig({
        environmentVariables: {foo: "bar"}
      })

    it "acts as getter", ->
      expect(@Cypress.env()).to.deep.eq({foo: "bar"})

    it "acts as getter with 1 string arg", ->
      expect(@Cypress.env("foo")).to.deep.eq("bar")

    it "acts as setter with key, value", ->
      @Cypress.env("bar", "baz")
      expect(@Cypress.env()).to.deep.eq({foo: "bar", bar: "baz"})

    it "acts as setter with object", ->
      @Cypress.env({bar: "baz"})
      expect(@Cypress.env()).to.deep.eq({foo: "bar", bar: "baz"})

    it "throws when Cypress.environmentVariables is undefined", ->
      delete @Cypress.environmentVariables

      fn = =>
        @Cypress.env()

      expect(fn).to.throw("Cypress.environmentVariables is not defined. Open an issue if you see this message.")

  describe "#setConfig", ->
    beforeEach ->
      @trigger = @sandbox.spy @Cypress, "trigger"

    it "instantiates EnvironmentVariables", ->
      expect(@Cypress).not.to.have.property("environmentVariables")
      @Cypress.setConfig({foo: "bar"})
      expect(@Cypress.environmentVariables).to.be.instanceof($Cypress.EnvironmentVariables)

    it "passes config.environmentVariables", ->
      @Cypress.setConfig({
        environmentVariables: {foo: "bar"}
      })

      expect(@Cypress.env()).to.deep.eq({foo: "bar"})

    it "triggers 'config'", ->
      @Cypress.setConfig({foo: "bar"})
      expect(@trigger).to.be.calledWith("config", {foo: "bar"})

    it "passes config to Config.create", ->
      @Cypress.setConfig({foo: "bar"})
      expect(@Cypress.config()).to.deep.eq({foo: "bar"})
      expect(@Cypress.config("foo")).to.eq("bar")

    it "can modify config values", ->
      @Cypress.setConfig({foo: "bar"})
      @Cypress.config("bar", "baz")
      expect(@Cypress.config()).to.deep.eq({foo: "bar", bar: "baz"})

    it "can set object literal as values", ->
      @Cypress.setConfig({foo: "bar"})
      @Cypress.config({foo: "baz", bar: "baz"})
      expect(@Cypress.config()).to.deep.eq({foo: "baz", bar: "baz"})

  describe "#onSpecWindow", ->
    beforeEach ->
      _.each ["Cy", "Chai", "Mocha", "Runner"], (klass) =>
        @sandbox.stub(@Cypress[klass], "create").returns(klass)

      @Cypress.onSpecWindow({})

    it "creates cy", ->
      expect(@Cypress.Cy.create).to.be.calledWith(@Cypress, {})

    it "creates chai", ->
      expect(@Cypress.Chai.create).to.be.calledWith(@Cypress, {})

    it "creates mocha", ->
      expect(@Cypress.Mocha.create).to.be.calledWith(@Cypress, {})

    it "creates runner", ->
      expect(@Cypress.Runner.create).to.be.calledWith(@Cypress, {}, "Mocha")

  describe ".$", ->
    it "proxies back to cy.$$", ->
      cy = {$$: @sandbox.spy()}
      @Cypress.cy = cy
      @Cypress.$("foo", "bar")
      expect(cy.$$).to.be.calledWith("foo", "bar")
      expect(cy.$$).to.be.calledOn(cy)

    it "proxies Deferred", (done) ->
      expect(@Cypress.$.Deferred).to.be.a("function")

      df = @Cypress.$.Deferred()

      _.delay ->
        df.resolve()
      , 10

      df.done -> done()

    _.each "Event Deferred ajax get getJSON getScript post when".split(" "), (fn) =>
      it "proxies $.#{fn}", ->
        expect(@Cypress.$[fn]).to.be.a("function")

  describe "._", ->
    it "is a reference to underscore", ->
      expect(@Cypress._).to.eq(window._)

  describe ".Blob", ->
    it "is a reference to underscore", ->
      expect(@Cypress.Blob).to.eq(window.blobUtil)

  describe ".Promise", ->
    it "is a reference to underscore", ->
      expect(@Cypress.Promise).to.eq(window.Promise)

  describe ".minimatch", ->
    it "is a reference to minimatch function", ->
      expect(@Cypress.minimatch("/foo/bar/baz", "/foo/**")).to.be.true
