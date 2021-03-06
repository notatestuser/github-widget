###
# to minify:
java -jar /usr/local/closure-compiler/compiler.jar \
  --compilation_level SIMPLE_OPTIMIZATIONS \
  --js github-widget.js \
  --js_output_file github-widget.min.js
###

###* @preserve https://github.com/jawj/github-widget
Copyright (c) 2011 - 2012 George MacKerron
Released under the MIT licence: http://opensource.org/licenses/mit-license ###

makeWidget = (payload, div) ->
  make cls: 'gw-clearer', prevSib: div
  user = div.getAttribute('data-user')
  siteRepoName = "#{user}.github.com"
  limit = parseInt div.getAttribute('data-limit') or Infinity
  sortBy = div.getAttribute('data-sortby') or 'watchers'
  for repo in payload.data.sort((a, b) -> b[sortBy] - a[sortBy]).slice(0, limit)
    continue if repo.fork or repo.name is siteRepoName or not repo.description
    make parent: div, cls: 'gw-repo-outer', kids: [
      make cls: 'gw-repo', kids: [
        make cls: 'gw-title', kids: [
          make tag: 'ul', cls: 'gw-stats', kids: [
            make tag: 'li', text: repo.watchers, cls: 'gw-watchers'
            make tag: 'li', text: repo.forks, cls: 'gw-forks']
          make tag: 'a', href: repo.html_url, text: repo.name, cls: 'gw-name']
        make cls: 'gw-lang', text: repo.language if repo.language?
        make cls: 'gw-repo-desc', text: repo.description]]

init = ->
  for div in (get tag: 'div', cls: 'github-widget')
    do (div) ->  # close over correct div
      url = "https://api.github.com/users/#{div.getAttribute 'data-user'}/repos?callback=<cb>"
      jsonp url: url, success: (payload) -> makeWidget payload, div


# support functions

cls = (el, opts = {}) ->  # cut-down version: no manipulation support
  classHash = {}
  classes = el.className.match(cls.re)
  if classes?
    (classHash[c] = yes) for c in classes
  hasClasses = opts.has?.match(cls.re)
  if hasClasses?
    (return no unless classHash[c]) for c in hasClasses
    return yes
  null

cls.re = /\S+/g

get = (opts = {}) ->
  inside = opts.inside ? document
  tag = opts.tag ? '*'
  if opts.id?
    return inside.getElementById opts.id
  hasCls = opts.cls?
  if hasCls and tag is '*' and inside.getElementsByClassName?
    return inside.getElementsByClassName opts.cls
  els = inside.getElementsByTagName tag
  if hasCls then els = (el for el in els when cls el, has: opts.cls)
  if not opts.multi? and tag.toLowerCase() in get.uniqueTags then els[0] ? null else els

get.uniqueTags = 'html body frameset head title base'.split(' ')

text = (t) -> document.createTextNode '' + t

make = (opts = {}) ->  # opts: tag, parent, prevSib, text, cls, [attrib]
  t = document.createElement opts.tag ? 'div'
  for own k, v of opts
    switch k
      when 'tag' then continue
      when 'parent' then v.appendChild t
      when 'kids' then t.appendChild c for c in v when c?
      when 'prevSib' then v.parentNode.insertBefore t, v.nextSibling
      when 'text' then t.appendChild text v
      when 'cls' then t.className = v
      else t[k] = v
  t

jsonp = (opts) ->
  callbackName = opts.callback ? '_JSONPCallback_' + jsonp.callbackNum++
  url = opts.url.replace '<cb>', callbackName
  window[callbackName] = opts.success ? jsonp.noop
  make tag: 'script', src: url, parent: (get tag: 'head')

jsonp.callbackNum = 0
jsonp.noop = ->

# do it!

init()
