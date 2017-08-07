CommentTitleView = require './comment-title-view'
{CompositeDisposable} = require 'atom'

module.exports = CommentTitle =
  commentTitleView: null
  modalPanel: null
  subscriptions: null

  activate: (state) ->
    @commentTitleView = new CommentTitleView(state.commentTitleViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @commentTitleView.getElement(), visible: false)

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view
    @subscriptions.add atom.commands.add 'atom-workspace', 'comment-title:toggle': => @toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'comment-title:wrap': => @wrap()

  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @commentTitleView.destroy()

  serialize: ->
    commentTitleViewState: @commentTitleView.serialize()

  toggle: ->
    console.log 'CommentTitle was toggled!'

    if @modalPanel.isVisible()
      @modalPanel.hide()
    else
      @modalPanel.show()

  wrap: ->
    editor = atom.workspace.getActiveTextEditor()
    comment = '# ' # default

    switch editor.getGrammar().name
      when 'SQL' then comment = '--'
      when 'Clojure', 'Scheme', 'Lisp' then comment = ';;'
      when 'RSpec', 'Nginx', 'YAML', 'Jinja Templates', 'Dockerfile', 'CoffeeScript', 'Git Config', 'Null Grammar', 'Ruby', 'Ruby on Rails', 'Shell Script', 'Unix Shell', 'Plain Text', 'Python' then comment = '#'
      when 'C', 'C++', 'Go', 'SASS', 'Lass', 'Javascript', 'TypeScript', 'PHP' then comment = '//'
      when 'Octave', 'Matlab', 'LaTeX' then comment = '%'

    @wrap_helper(editor, comment)

  wrap_helper: (editor, comment) ->
    line = editor.getSelectedText()
    if not line
      editor.selectLinesContainingCursors(); editor.selectLeft()
      line = editor.getSelectedText()

    trimmed = line.replace(/^\s+|\s+$/g, '')      # remove leading/trailing spaces
    wrapped = "#{comment} #{trimmed} #{comment}"  # wrap  the trimmed line in comments

    # add extra space for symmetry
    len = comment.length
    rem = wrapped.length % len
    if rem
      extra_space = Array(rem + 1).join(' ')
      wrapped = "#{comment} #{trimmed} #{extra_space}#{comment}"

    # header/footer
    around = Array(wrapped.length // len + 1).join(comment)

    editor.insertText("#{around}\n#{wrapped}\n#{around}")
