local snippet_engines = require("snippet_converter.snippet_engines")
local loader = require("snippet_converter.loader")

local M = {}

local function validate_sources(sources)
  vim.validate({
    sources = {
      sources,
      "table",
    },
  })
  local supported_formats = vim.tbl_keys(snippet_engines)
  for source_format, source_paths in ipairs(sources) do
    vim.validate({
      ["name of the source"] = {
        source_format,
        function(arg)
          return vim.tbl_contains(supported_formats, arg)
        end,
        "one of " .. vim.fn.join(supported_formats, ", "),
      },
    })
    for _, source_path in ipairs(source_paths) do
      vim.validate({
        source_path = {
          source_path,
          "string", -- TODO: support * as path to find all files matching extension in rtp
        },
      })
    end
  end
end

local config
M.setup = function(user_config)
  validate_sources(user_config.sources)
  config = user_config
end

-- Partitions the snippet paths into a table of <filetype, [snippet_paths]>
-- (e.g. filetype of an input file "lua.snippets" is "lua").

-- @return <string, string> a table where each key is a filetype
-- and each value is a list of snippet paths that correspond to that filetype
local partition_snippet_paths = function(snippet_paths)
  local partitioned_snippet_paths = {}
  for _, snippet_path in ipairs(snippet_paths) do
    local filetype = vim.fn.fnamemodify(snippet_path, ":t:r")
    local snippet_paths_for_ft = partitioned_snippet_paths[filetype]
    if snippet_paths_for_ft == nil then
      snippet_paths_for_ft = {}
    end
    snippet_paths_for_ft[#snippet_paths_for_ft + 1] = snippet_path
    partitioned_snippet_paths[filetype] = snippet_paths_for_ft
  end
  return partitioned_snippet_paths
end

local load_snippets = function(sources)
  local snippet_paths = {}
  for source_format, source_paths in pairs(sources) do
    local _snippet_paths = loader.get_matching_snippet_paths(source_format, source_paths)
    snippet_paths[source_format] = partition_snippet_paths(_snippet_paths)
  end
  return snippet_paths
end

local parse_snippets = function(snippet_paths, sources)
  local snippets = {}
  for source_format, _ in pairs(sources) do
    local parser = require(snippet_engines[source_format].parser)
    for filetype, paths in pairs(snippet_paths[source_format]) do
      if snippets[filetype] == nil then
        snippets[filetype] = {}
      end
      for _, path in ipairs(paths) do
        parser.parse(snippets[filetype], parser.get_lines(path))
      end
    end
  end
  return snippets
end

local convert_snippets = function(snippets, output)
  local failures = {}
  for target_format, output_paths in pairs(output) do
    local converter = require(snippet_engines[target_format].converter)
    for filetype, _snippets in pairs(snippets) do
      local converted_snippets = {}
      local pos = 1
      for _, snippet in ipairs(_snippets) do
        local ok, converted_snippet = pcall(converter.convert, snippet)
        if ok then
          converted_snippets[pos] = converted_snippet
          pos = pos + 1
        else
          failures[#failures + 1] = {
            msg = converted_snippet,
            -- snippet = converted_snippet,
          }
        end
      end
      for _, output_path in ipairs(output_paths) do
        converter.export(converted_snippets, filetype, output_path)
      end
    end
  end
  return failures
end

M.convert_snippets = function()
  if config == nil then
    error("setup function must be called with valid config before converting snippets")
    return
  end

  local snippet_paths = load_snippets(config.sources)
  local snippets = parse_snippets(snippet_paths, config.sources)
  local failures = convert_snippets(snippets, config.output)
  print(vim.inspect(failures))
end

return M
