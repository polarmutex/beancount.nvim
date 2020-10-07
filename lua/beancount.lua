local queries = require "nvim-treesitter.query"

local M = {}

-- TODO: In this function replace `module-template` with the actual name of your module.
function M.init()

    require "nvim-treesitter.parsers".get_parser_configs().beancount = {
        install_info = {
            url = "https://github.com/bryall/tree-sitter-beancount",
            files = {"src/parser.c"}
        }
    }

    require "nvim-treesitter".define_modules {
        beancount = {
            module_path = "nvim-beancount.internal",
            is_supported = function(lang)
                return lang == 'beancount'
            end
        }
    }
end
-- TODO: Think about how to do this.
local function insert_value(prompt_bufnr)
    local actions = require('telescope.actions')
    local entry = actions.get_selected_entry(prompt_bufnr)

    vim.schedule(function()
        actions.close(prompt_bufnr)
    end)


    local bufnr = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    vim.api.nvim_buf_set_lines(bufnr, row, row, false, lines)
end

function M.CopyTransaction(opts)
    local opts = opts or {}

    local has_nvim_treesitter, nvim_treesitter = pcall(require, 'nvim-treesitter')
    if not has_nvim_treesitter then
        print('You need to install nvim-treesitter')
        return
    end

    local parsers = require('nvim-treesitter.parsers')
    if not parsers.has_parser() then
        print('No parser for the current buffer')
        return
    end

    local has_telescope, _ = pcall(require, 'telescope')
    if not has_telescope then
        print('telescope.nvim not installed')
        return
    end

    --local ts_locals = require('nvim-treesitter.locals')
    local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

    local results = require('beancount.copytransactions').list_transactions(bufnr)
    if vim.tbl_isempty(results) then
        return
    end

    local pickers = require('telescope.pickers')
    local finders = require('telescope.finders')
    local make_entry = require('telescope.make_entry')
    local sorters = require('telescope.sorters')
    local previewers = require('telescope.previewers')
    local actions = require('telescope.actions')
    pickers.new(opts, {
        prompt    = 'Transactions',
        finder    = finders.new_table {
            results = results,
            entry_maker = make_entry.gen_from_string(opts)
        },
        previewer = previewers.vim_buffer.new(opts),
        sorter    = sorters.get_generic_fuzzy_sorter(),
        attach_mappings = function( prompt_bufnr, map)
            local insert_txn = function ()
                local selection = actions.get_selected_entry(prompt_bufnr)
                actions.close(prompt_bufnr)

                local lines = {}
                for str in string.gmatch(selection.display, "([^" .. "\n" .. "]+)") do
                    table.insert(lines, str)
                end

                local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                vim.api.nvim_buf_set_lines(bufnr, row, row, false, lines)
            end
            map('i', '<CR>', insert_txn)
            return true
        end,
    }):find()
end

return M
