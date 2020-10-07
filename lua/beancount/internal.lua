local api = vim.api
local ts = vim.treesitter

local highlights = require "nvim-treesitter.highlight"
local queries = require "nvim-treesitter.query"
local parsers = require "nvim-treesitter.parsers"
local configs = require "nvim-treesitter.configs"
local ts_utils = require "nvim-treesitter.ts_utils"

local M = {
}

function M.attach(bufnr, lang)
  --local bufnr = bufnr or api.nvim_get_current_buf()
  --local lang = lang or parsers.get_buf_lang(bufnr)
  --local config = configs.get_module('hightlight')
  --local query = queries.get_query(lang, "highlights")
  --if not query then
  --    return
  --end

  --M.highlighters[bufnr] = ts.TSHighlighter.new(query, bufnr, lang)
end

function M.detach(bufnr)
  -- TODO: Fill this with what you need to do when detaching from a buffer
end

local function reverse(t)
    local n = #t
    local i = 1
    while i < n do
        t[i],t[n] = t[n],t[i]
        i = i + 1
        n = n - 1
    end
end

local function list_transactions(bufnr)
    local matches = queries.get_capture_matches(bufnr, "@txn", 'textobjects')

    -- TODO this is returning double nodes for each node

    local txns = {}
    local i = 1
    for _, m in ipairs(matches) do
        --if math.fmod(_,2) == 0 then
            if m.node then
                local txn_string = ""
                for _, line in pairs(ts_utils.get_node_text(m.node, bufnr)) do
                    txn_string = txn_string .. "\n" .. line
                end
                txns[i] = txn_string
                i = i + 1
            end
        --end
    end

    reverse(txns)

    return txns
end

local function write_transaction(result)
    local bufnr = vim.api.nvim_get_current_buf()

    lines = {}
    for str in string.gmatch(result, "([^" .."\n" .. "]+)") do
        table.insert(lines, str)
    end

    local row, col = unpack(api.nvim_win_get_cursor(0))

    api.nvim_buf_set_lines(bufnr,row, row, false, lines)
end

local function prepare_match(entry, kind)
  local entries = {}

  if entry.node then
      entry["kind"] = kind
      table.insert(entries, entry)
  else
    for name, item in pairs(entry) do
        vim.list_extend(entries, prepare_match(item, name))
    end
  end

  return entries
end


return M
