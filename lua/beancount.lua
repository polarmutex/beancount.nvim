local M = {}

function M.init()
    --TODO do I need this?
    --require('nvim-treesitter').define_modules({
    --    beancount = {
    --        module_path = 'nvim-beancount.internal',
    --        is_supported = function(lang)
    --            return lang == 'beancount'
    --        end,
    --    },
    --})
    require('vim.treesitter.query').set(
        'beancount',
        'locals',
        [[(transaction
    (date) @definition.date
    (narration) @definition.payee) @definition.transaction
]]
    )
end

M.check_nvim_treesitter = function(utils)
    local has_nvim_treesitter, _ = pcall(require, 'nvim-treesitter')
    if not has_nvim_treesitter then
        if utils ~= nil then
            utils.notify('builtin.treesitter', {
                msg = 'User need to install nvim-treesitter needs to be installed',
                level = 'ERROR',
            })
        end
        return false
    end
    return true
end

M.check_nvim_treesitter_parser = function(bufnr, utils)
    local parsers = require('nvim-treesitter.parsers')
    if not parsers.has_parser(parsers.get_buf_lang(bufnr)) then
        if utils ~= nil then
            utils.notify('builtin.treesitter', {
                msg = 'No parser for the current buffer',
                level = 'ERROR',
            })
        end
        return false
    end
    return true
end

local function prepare_match(entry, kind)
    local entries = {}

    if entry.node then
        --entry["kind"] = kind
        table.insert(entries, entry)
    else
        for name, item in pairs(entry) do
            vim.list_extend(entries, prepare_match(item, name))
        end
    end

    return entries
end

M.get_transactions = function(bufnr)
    local ts_locals = require('nvim-treesitter.locals')
    local results = {}
    for _, definition in ipairs(ts_locals.get_definitions(bufnr)) do
        local entries = prepare_match(ts_locals.get_local_nodes(definition))
        for _, entry in ipairs(entries) do
            entry.kind = vim.F.if_nil(entry.kind, '')
            if entry.kind == 'transaction' then
                table.insert(results, entry)
            end
        end
    end
    return results
end

M.reverse = function(t)
    local n = #t
    local i = 1
    while i < n do
        t[i], t[n] = t[n], t[i]
        i = i + 1
        n = n - 1
    end
end

return M
