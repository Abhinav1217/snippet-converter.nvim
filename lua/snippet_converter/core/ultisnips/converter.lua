local NodeType = require("snippet_converter.core.node_type")
local Variable = require("snippet_converter.core.vscode.body_parser").Variable
local base_converter = require("snippet_converter.core.converter")
local io = require("snippet_converter.utils.io")
local export_utils = require("snippet_converter.utils.export_utils")

local M = {}

-- Determines whether the provided snippet can be converted from UltiSnips
-- to other formats (e.g. python interpolation is an UltiSnips-only feature).
M.can_convert = function(snippet, target_engine)
  local body = vim.fn.join(snippet.body, "")
  -- Must not contain interpolation code
  return not body:match("`[^`]*`")
end

local convert_variable = setmetatable({
  [Variable.TM_FILENAME] = [[`!v expand('%:t')`]],
  [Variable.TM_FILENAME_BASE] = [[`!v expand('%:t:r')`]],
  [Variable.TM_DIRECTORY] = [[`!v expand('%:p:r')`]],
  [Variable.TM_FILEPATH] = [[`!v expand('%:p')`]],
  [Variable.RELATIVE_FILEPATH] = [[`!v expand('%:p:.')`]],
  [Variable.CLIPBOARD] = [[`!v getreg(v:register)`]],
  [Variable.CURRENT_YEAR] = [[`!v !v strftime('%Y')`]],
  [Variable.CURRENT_YEAR_SHORT] = [[`!v strftime('%y')`]],
  [Variable.CURRENT_MONTH] = [[`!v strftime('%m')`]],
  [Variable.CURRENT_MONTH_NAME] = [[`!v strftime('%B')`]],
  [Variable.CURRENT_MONTH_NAME_SHORT] = [[`!v strftime('%b')`]],
  [Variable.CURRENT_DATE] = [[`!v strftime('%b')`]],
  [Variable.CURRENT_DAY_NAME] = [[`!v strftime('%A')`]],
  [Variable.CURRENT_DAY_NAME_SHORT] = [[`!v strftime('%a')`]],
  [Variable.CURRENT_HOUR] = [[`!v strftime('%H')`]],
  [Variable.CURRENT_MINUTE] = [[`!v strftime('%M')`]],
  [Variable.CURRENT_SECOND] = [[`!v strftime('%S')`]],
  [Variable.CURRENT_SECONDS_UNIX] = [[`!v localtime()`]],
}, {
  __index = function(_, key)
    error("failed to convert unknown variable " .. key)
  end,
})

M.visit_node = setmetatable({
  [NodeType.VARIABLE] = function(node)
    if node.transform then
      error("cannot convert variable with transform")
    end
    local var = convert_variable[node.var]
    if node.any then
      local any = base_converter.convert_node_recursive(node.any, M.visit_node)
      return string.format("${%s:%s}", var, any)
    end
    return var
  end,
}, {
  __index = base_converter.visit_node(M.visit_node),
})

M.convert = function(snippet, source_format)
  local trigger = snippet.trigger
  -- Literal " in trigger
  if trigger:match([["]]) then
    trigger = string.format("!%s!", trigger)
    -- Multi-word trigger
  elseif trigger:match("%s") then
    trigger = string.format([["%s"]], trigger)
  end
  local description = ""
  -- Description must be quoted
  if snippet.description then
    description = string.format([[ "%s"]], snippet.description)
  end
  local body = base_converter.convert_ast(snippet.body, M.visit_node)
  return string.format("snippet %s%s\n%s\nendsnippet", trigger, description, body)
end

local HEADER_STRING =
  "# Generated by snippet-converter.nvim (https://github.com/smjonas/snippet-converter.nvim)"

-- Takes a list of converted snippets for a particular filetype,
-- separates them by newlines and exports them to a file.
-- @param converted_snippets string[] @A list of strings where each item is a snippet string to be exported
-- @param filetype string @The filetype of the snippets
-- @param output_dir string @The absolute path to the directory (or file) to write the snippets to
M.export = function(converted_snippets, filetype, output_path)
  local snippet_lines = export_utils.snippet_strings_to_lines(
    converted_snippets,
    "\n",
    HEADER_STRING,
    nil
  )
  output_path = export_utils.get_output_path(output_path, filetype, "snippets")
  io.write_file(snippet_lines, output_path)
end

return M
