wesabe.provide('download.CompoundPlayer')

class wesabe.download.CompoundPlayer
  @register: (params) ->
    klass = @create(params)

    # make sure we put it where wesabe.require expects it
    wesabe.provide("fi-scripts.#{klass.fid}", klass)

    return klass

  @create: (params) ->
    class klass extends this
      @fid: params.fid
      @org: params.org

    wesabe.lang.extend(klass.prototype, params)

    return klass

  playerIndex: -1
  currentJob: null
  players: null

  start: (answers, browser) ->
    startNextPlayer = (failureCallback) =>
      nextPlayer()
      while @currentPlayer and not @currentPlayer.canHandleGoal(@job.goal)
        wesabe.warn("Skipping player ", @currentPlayer, " since it can't handle goal: ", @job.goal)
        nextPlayer()

      if @currentPlayer
        wesabe.info("Starting player ", @currentPlayer)
        @currentPlayer.job = jobProxy
        @currentPlayer.start(answers, browser)
      else if failureCallback
        failureCallback()
      else
        wesabe.info("No more players to handle goal: ", jobProxy.goal)
        @job.fail(400, "goal.unreachable")

    nextPlayer = =>
      @currentPlayer?.job = null

      if playerClass = @players[++@playerIndex]
        @currentPlayer = new playerClass()
        @currentPlayer.job = jobProxy
      else
        @currentPlayer = null

    jobProxy =
      # pass all method calls through
      __noSuchMethod__: (method, args) =>
        @job[method].apply(@job, args)

      # handle properties
      timer: @job.timer
      options: @job.options
      data: @job.data

      # customize fail to go to the next player
      fail: (status, result) =>
        wesabe.info("Could not complete job with ", @currentPlayer, " (", status, " ", result, ")")

        # if we can't, just report the last failure
        startNextPlayer(=> @job.fail(status, result))

    jobProxy.__defineGetter__ 'page', =>
      @currentPlayer.page

    jobProxy.__defineGetter__ 'goal', =>
      @job.goal

    startNextPlayer()

  resume: (args...) ->
    @currentPlayer?.resume(args...)

  onLastGoalFinished: (args...) ->
    @currentPlayer?.onLastGoalFinished?(args...)

  onDownloadSuccessful: (args...) ->
    @currentPlayer?.onDownloadSuccessful?(args...)

  @::__defineGetter__ 'browser', ->
    @currentPlayer?.browser
