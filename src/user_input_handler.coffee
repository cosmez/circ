exports = window

class UserInputHandler extends EventEmitter
  @ENTER_KEY = 13
  @UP = 38
  @DOWN = 40
  @TAB = 9

  constructor: (@input, @window) ->
    super
    @input.focus()
    @inputStack = new InputStack
    @autoComplete = new AutoComplete @_getCompletions
    @input.keydown @_handleKeydown
    @window.keydown @_handleGlobalKeydown

  _getCompletions: =>
    chan = @context.currentWindow.target
    nicks = @context.currentWindow.conn?.irc.channels[chan]?.names
    return if nicks? then (nick for norm, nick of nicks) else []

  setContext: (@context) ->

  _handleGlobalKeydown: (e) =>
    @_handleFocusingInput e
    @_handleSwitchingWindows e
    @_handleShowingPreviousCommands e
    @_handleAutoComplete e

  _handleFocusingInput: (e) ->
    unless e.metaKey or e.ctrlKey
      e.currentTarget = @input[0]
      @input.focus()

  _handleSwitchingWindows: (e) ->
    if e.altKey and 48 <= e.which <= 57
      @emit 'switch_window', e.which - 48
      e.preventDefault()

  _handleShowingPreviousCommands: (e) ->
    if e.which == UserInputHandler.UP or e.which == UserInputHandler.DOWN
      e.preventDefault()
      if e.which == UserInputHandler.UP
        @inputStack.setCurrentText @input.val()
        input = @inputStack.showPreviousInput()
      else
        input = @inputStack.showNextInput()
      @input.val(input) if input?
    else
      @inputStack.reset()

  _handleAutoComplete: (e) ->
    if e.which == UserInputHandler.TAB
      e.preventDefault()
      unless @input.val() == ''
        words = @input.val().split /\s/
        completion = @autoComplete.getCompletion words[words.length-1]
        words[words.length-1] = completion
        @input.val words.join ' '
    else
      @autoComplete.reset()

  _handleKeydown: (e) =>
    if e.which == UserInputHandler.ENTER_KEY
      text = @input.val()
      if text.length > 0
        @input.val('')
        @_handleTextInput text

  _handleTextInput: (text) =>
    @inputStack.addInput text
    words = text.split(/\s+/)
    if text[0] == '/'
      name = words[0][1..].toLowerCase()
      text = words[1..]
    else
      name = 'say'
      text = words
    server = @context.currentWindow.conn?.name
    channel = @context.currentWindow.target
    event = new Event 'command', name, text...
    event.setContext server, channel
    @emit event.type, event

exports.UserInputHandler = UserInputHandler