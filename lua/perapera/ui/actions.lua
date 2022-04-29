local async = require("perapera.async")
local engines = require("perapera.engines")
local handlers = require("perapera.handlers")
local actions = {}

function actions.help()
  error("Not implemented!") -- TODO
end

function actions.yank_close_translation(ui)
  local translation = ui.translation
  ui:close()
  handlers.yank(translation)
end

function actions.yank_close_input(ui)
  local input = ui.input
  ui:close()
  handlers.yank(input)
end

function actions.replace_close_translation(ui)
  local coords, translation = ui.coords, ui.translation
  ui:close()
  handlers.replace(translation, coords)
end

function actions.replace_close_input(ui)
  local coords, input = ui.coords, ui.input
  ui:close()
  handlers.replace(input, coords)
end

function actions.append_close_translation(ui)
  local coords, translation = ui.coords, ui.translation
  ui:close()
  handlers.append(translation, coords)
end

function actions.append_close_input(ui)
  local coords, input = ui.coords, ui.input
  ui:close()
  handlers.append(input, coords)
end

function actions.close(ui)
  ui:close()
end

actions.switch_languages = async.wrap(function(ui)
  ui:lock()
  local prv, src, tgt, dtc, new_src, new_tgt = ui.previous, ui.source, ui.target, ui.detected
  if not dtc and prv.source and prv.source[src] and prv.target and prv.target[tgt] then
    new_src, new_tgt = prv.source[src], prv.target[tgt]
  else
    new_src, new_tgt = ui.engine.switch(dtc or src, tgt)
  end

  if new_src ~= (dtc or src) or ui.target ~= tgt then
    ui.input, ui.translation = ui.translation, ui.input
    ui.source = new_src
    ui.target = new_tgt
    ui.detected = nil
    actions.translate(ui, true)
  end

  -- put source and target in different tables for the edge case that they are the same
  prv.source = {[ui.source] = src}
  prv.target = {[ui.target] = tgt}
  ui:unlock()
end)

actions.translate = async.wrap(function(ui, force)
  ui:lock()
  if force or ui.input ~= ui.previous.input then
    local translated = #ui.input > 0 and ui.engine.translate(ui.input, ui.source, ui.target) or {}

    ui.previous.input = ui.input
    ui.translation = translated.text
    ui.detected = translated.detected
  end
  ui:unlock()
end)

actions.select_source = async.wrap(function(ui)
  ui:lock()
  local langs = ui.engine.languages().source
  ui:select_left(vim.tbl_keys(langs), {format_item = function(l) return langs[l] end}, function(lang)
    if lang then
      ui.source = lang
      actions.translate(ui, true)
    end
  end)
  ui:unlock()
end)

actions.select_target = async.wrap(function(ui)
  ui:lock()
  local langs = ui.engine.languages().target
  ui:select_right(vim.tbl_keys(langs), {format_item = function(l) return langs[l] end}, function(lang)
    if lang then
      ui.target = lang
      actions.translate(ui, true)
    end
  end)
  ui:unlock()
end)

actions.select_engine = async.wrap(function(ui)
  ui:lock()
  ui:select_left(vim.tbl_keys(engines), nil, function(name)
    if name then
      local engine = engines[name]
      ui.engine = engine
      ui.source = engine.config.default_source
      ui.target = engine.config.default_target
      ui.detected = nil
      actions.translate(ui, true)
    end
  end)
  ui:unlock()
end)

function actions.select_next(ui)
  ui.select:next()
end

function actions.select_prev(ui)
  ui.select:prev()
end

function actions.select_choose(ui)
  ui.select:choose()
end

function actions.select_abort(ui)
  ui.select:abort()
end

function actions.select_first(ui)
  ui.select:first()
end

function actions.select_last(ui)
  ui.select:last()
end

return actions
