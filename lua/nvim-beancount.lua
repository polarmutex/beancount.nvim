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

return M
