local entry_display = require('telescope.pickers.entry_display')
local utils = require('telescope.utils')
local strings = require('plenary.strings')
local Path = require('plenary.path')

local treesitter_type_highlight = {
    ['associated'] = 'TSConstant',
    ['constant'] = 'TSConstant',
    ['field'] = 'TSField',
    ['function'] = 'TSFunction',
    ['method'] = 'TSMethod',
    ['parameter'] = 'TSParameter',
    ['property'] = 'TSProperty',
    ['struct'] = 'Struct',
    ['var'] = 'TSVariableBuiltin',
}

local make_entry_treesitter = function(opts)
    opts = opts or {}

    local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

    local display_items = {
        { width = 25 },
        { width = 10 },
        { remaining = true },
    }

    if opts.show_line then
        table.insert(display_items, 2, { width = 6 })
    end

    local displayer = entry_display.create({
        separator = ' ',
        items = display_items,
    })

    local type_highlight = opts.symbol_highlights or treesitter_type_highlight

    local make_display = function(entry)
        local msg = vim.api.nvim_buf_get_lines(bufnr, entry.lnum, entry.lnum, false)[1] or ''
        msg = vim.trim(msg)

        local display_columns = {
            entry.text,
            { entry.kind, type_highlight[entry.kind], type_highlight[entry.kind] },
            msg,
        }
        if opts.show_line then
            table.insert(display_columns, 2, { entry.lnum .. ':' .. entry.col, 'TelescopeResultsLineNr' })
        end

        return displayer(display_columns)
    end

    return function(entry)
        local ts_utils = require('nvim-treesitter.ts_utils')
        local start_row, start_col, end_row, _ = ts_utils.get_node_range(entry.node)
        --local node_text = vim.treesitter.query.get_node_text(entry.node, bufnr)
        local node_text = ts_utils.get_node_text(entry.node, bufnr)[1]
        return {
            valid = true,

            value = entry.node,
            kind = entry.kind,
            ordinal = node_text .. ' ' .. (entry.kind or 'unknown'),
            display = make_display,

            node_text = node_text,

            filename = vim.api.nvim_buf_get_name(bufnr),
            -- need to add one since the previewer substacts one
            lnum = start_row + 1,
            col = start_col,
            text = node_text,
            start = start_row,
            finish = end_row,
        }
    end
end
local copy_transactions = function(opts)
    local opts = opts or {}

    local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

    local pickers = require('telescope.pickers')
    local utils = require('telescope.utils')
    local finders = require('telescope.finders')
    local make_entry = require('telescope.make_entry')
    local conf = require('telescope.config').values
    --local finders = require("telescope.finders")
    --local make_entry = require("telescope.make_entry")
    --local sorters = require("telescope.sorters")
    --local previewers = require("telescope.previewers")
    --local conf = require("telescope.config").values
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

    local beancount_nvim = require('beancount')
    beancount_nvim.check_nvim_treesitter(utils)
    beancount_nvim.check_nvim_treesitter_parser(bufnr, utils)

    local results = beancount_nvim.get_transactions(bufnr)
    beancount_nvim.reverse(results)

    if vim.tbl_isempty(results) then
        return
    end

    pickers.new(opts, {
        prompt_title = 'Transactions',
        finder = finders.new_table({
            results = results,
            --TODO fix changes from telescope master
            --entry_maker = opts.entry_maker or make_entry.gen_from_treesitter(opts),
            entry_maker = make_entry_treesitter(opts),
        }),
        previewer = conf.grep_previewer(opts),
        sorter = conf.prefilter_sorter({
            tag = 'kind',
            sorter = conf.generic_sorter(opts),
        }),
        attach_mappings = function(prompt_bufnr, map)
            local insert_txn = function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                local lines = vim.api.nvim_buf_get_lines(bufnr, selection.start, selection.finish, false)

                local row, col = unpack(vim.api.nvim_win_get_cursor(0))
                vim.api.nvim_buf_set_lines(bufnr, row, row, false, lines)
            end
            map('i', '<CR>', insert_txn)
            return true
        end,
    }):find()
end

return require('telescope').register_extension({
    setup = function()
        require('beancount').init()
    end,
    exports = {
        copy_transactions = copy_transactions,
    },
})
