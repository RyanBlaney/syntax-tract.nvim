local M = {}
local defaults = require('syntax-tract.defaults').defaults

-- Default options
M.setup = function(opts)
  -- Merge user options with default options
  M.opts = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Setup highlight group
  for lang, lang_opts in pairs(M.opts.languages) do
    vim.cmd(string.format("highlight SyntaxTractConcealed_%s ctermfg=LightRed guifg=%s", lang, lang_opts.color))
  end

  -- Function to conceal words
  M.conceal_words = function(bufnr, lang)
    local lang_opts = M.opts.languages[lang]
    if not lang_opts or not lang_opts.words then
      return
    end
    local ns_id = vim.api.nvim_create_namespace("syntax_tract")
    local hl_group = "SyntaxTractConcealed_" .. lang
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for linenr, line in ipairs(lines) do
      for word, symbol in pairs(lang_opts.words) do
        -- Escape special characters and add beginning-of-line anchor
        local pattern = word:gsub("([.*+?^$()%%{}|[\\]])", "%%%1")
        pattern = "^%s*" .. pattern -- Ensure it matches with optional leading whitespace

        -- Iterate over all matches in the line
        local start_pos = 1
        while true do
          local s, e = line:find(pattern, start_pos)
          if not s then break end
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, linenr-1, s-1, {
            end_col = e,
            conceal = symbol,
            hl_group = hl_group,
          })
          start_pos = e + 1
        end
      end
    end
  end

  -- Function to remove concealment on the current line
  M.reveal_line = function(bufnr, line_nr)
    local ns_id = vim.api.nvim_create_namespace("syntax_tract")
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_nr, line_nr + 1)
  end

  -- Setup autocommands for each language
  for lang, _ in pairs(M.opts.languages) do
    vim.cmd(string.format([[
      augroup SyntaxTract_%s
        autocmd!
        autocmd BufReadPost,BufWritePost *.%s lua require('syntax-tract').conceal_words(0, '%s')
        autocmd CursorMoved *.%s lua require('syntax-tract').reveal_line(0, vim.fn.line('.') - 1)
        autocmd CursorMoved *.%s lua require('syntax-tract').conceal_words(0, '%s')
      augroup END
    ]], lang, lang, lang, lang, lang, lang))
  end
end

return M
