local base_converter = require("snippet_converter.core.converter")
local io = require("snippet_converter.utils.io")
local export_utils = require("snippet_converter.utils.export_utils")

local M = {}

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

  local options = ""
  if source_format == "ultisnips" then
    if snippet.options then
      options = " " .. snippet.options
    end
  end
  local body = base_converter.convert_ast(snippet.body, base_converter.visit_node())
  return string.format("snippet %s%s%s\n%s\nendsnippet", trigger, description, options, body)
end

local HEADER_STRING =
  "# Generated by snippet-converter.nvim (https://github.com/smjonas/snippet-converter.nvim)"

-- Takes a list of converted snippets for a particular filetype,
-- separates them by newlines and exports them to a file.
-- @param converted_snippets string[] @A list of strings where each item is a snippet string to be exported
-- @param filetype string @The filetype of the snippets
-- @param output_dir string @The absolute path to the directory (or file) to write the snippets to
-- @param context []? @A table of additional snippet contexts optionally provided the source parser (example: global code)
M.export = function(converted_snippets, filetype, output_path, context)
  if context then
    for i, code in ipairs(context.global_code) do
      local lines = ("global !p\n%s\nendglobal"):format(table.concat(code, "\n"))
      -- Add global python code at the beginning of the output file
      table.insert(converted_snippets, i, lines)
    end
    for i, priority in pairs(context.priorities) do
      local line = "priority " .. priority
      if i == -1 then
        -- The priority applies to all snippets in the file
        table.insert(converted_snippets, -1, line)
      else
        -- Add priorities right before the next snippet
        converted_snippets[i + 1] = ("%s\n%s"):format(line, converted_snippets[i + 1])
      end
    end
  end

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
