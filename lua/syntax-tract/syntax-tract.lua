local M = {}

M.setup = function(opts)
  -- Default options
  local default_opts = {
    languages = {
      cpp = {
        words = {},
        color = "#ff8a8a",
      },
    },
  }

  -- Merge user options with default options
  M.opts = vim.tbl_deep_extend("force", default_opts, opts or {})

  -- Setup highlight group
  vim.cmd(string.format("highlight SyntaxTractConcealed ctermfg=LightRed guifg=%s", M.opts.languages.cpp.color))

  -- Function to conceal words
  local function conceal_words(bufnr, lang_opts)
    local ns_id = vim.api.nvim_create_namespace("syntax_tract")
    local hl_group = "SyntaxTractConcealed"
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for linenr, line in ipairs(lines) do
      for word, symbol in pairs(lang_opts.words) do
        local start_pos, end_pos = string.find(line, word)
        while start_pos do
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, linenr-1, start_pos-1, {
            end_col = end_pos,
            conceal = symbol,
            hl_group = hl_group,
          })
          start_pos, end_pos = string.find(line, word, end_pos + 1)
        end
      end
    end
  end

  -- Function to remove concealment on the current line
  local function reveal_line(bufnr, line_nr)
    local ns_id = vim.api.nvim_create_namespace("syntax_tract")
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_nr, line_nr + 1)
  end

  -- Setup autocommands for each language
  for lang, lang_opts in pairs(M.opts.languages) do
    vim.cmd(string.format([[
      augroup SyntaxTract_%s
        autocmd!
        autocmd BufReadPost,BufWritePost *.%s lua require('syntax_tract').conceal_words(0, '%s')
        autocmd CursorMoved *.%s lua require('syntax_tract').reveal_line(0, vim.fn.line('.') - 1)
        autocmd CursorMoved *.%s lua require('syntax_tract').conceal_words(0, '%s')
      augroup END
    ]], lang, lang, lang, lang, lang, lang))
  end

  -- Expose functions
  M.conceal_words = conceal_words
  M.reveal_line = reveal_line
end

return M
