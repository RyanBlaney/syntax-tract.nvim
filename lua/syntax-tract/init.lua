
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

  -- Function to conceal words and braces
  M.conceal_words_and_braces = function(bufnr, lang)
    local lang_opts = M.opts.languages[lang]
    if not lang_opts or not lang_opts.words then
      return
    end
    local ns_id = vim.api.nvim_create_namespace("syntax_tract")
    local hl_group = "SyntaxTractConcealed_" .. lang
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    -- Clear any existing extmarks and brace pairs
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    vim.b[bufnr].brace_pairs = {}

    -- Conceal words
    for linenr, line in ipairs(lines) do
      for word, symbol in pairs(lang_opts.words) do
        -- Escape special characters
        local escaped_word = word:gsub("([.*+?^$()%%{}|[\\]])", "%%%1")
        -- Use Lua's pattern matching to find the word
        local start_pos, end_pos = string.find(line, escaped_word)
        while start_pos do
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, linenr-1, start_pos-1, {
            end_col = end_pos,
            conceal = symbol,
            hl_group = hl_group,
          })
          start_pos, end_pos = string.find(line, escaped_word, end_pos + 1)
        end
      end
    end

    -- Use Treesitter to find brace pairs
    if lang_opts.hide_braces then
      local parser = vim.treesitter.get_parser(bufnr, lang)
      local tree = parser:parse()[1]
      local root = tree:root()

      local function traverse(node)
        if node:type() == "compound_statement" then
          local start_line, start_col, end_line, end_col = node:range()
          table.insert(vim.b[bufnr].brace_pairs, {
            open = { linenr = start_line, col = start_col },
            close = { linenr = end_line, col = end_col - 1 } -- Adjust end_col to point to the closing brace
          })
        end
        for child in node:iter_children() do
          traverse(child)
        end
      end

      traverse(root)

      -- Conceal the braces
      for _, pair in ipairs(vim.b[bufnr].brace_pairs) do
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, pair.open.linenr, pair.open.col, {
          end_col = pair.open.col + 1,
          conceal = "",
          hl_group = hl_group,
        })
        vim.api.nvim_buf_set_extmark(bufnr, ns_id, pair.close.linenr, pair.close.col, {
          end_col = pair.close.col + 1,
          conceal = "",
          hl_group = hl_group,
        })
      end
    end
  end

  -- Function to remove concealment on the current line and within brace scopes
  M.reveal_line_and_braces = function(bufnr, line_nr)
    local ns_id = vim.api.nvim_create_namespace("syntax_tract")
    vim.api.nvim_buf_clear_namespace(bufnr, ns_id, line_nr, line_nr + 1)

    -- Reveal scopes
    local brace_pairs = vim.b[bufnr].brace_pairs or {}
    print(string.format("Revealing line %d, brace_pairs count: %d", line_nr, #brace_pairs))
    for _, pair in ipairs(brace_pairs) do
      if (line_nr >= pair.open.linenr and line_nr <= pair.close.linenr) then
        print(string.format("Revealing brace pair: open(%d, %d), close(%d, %d)",
          pair.open.linenr, pair.open.col, pair.close.linenr, pair.close.col))
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, pair.open.linenr, pair.open.linenr + 1)
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, pair.close.linenr, pair.close.linenr + 1)
      end
    end
  end

  -- Setup autocommands for each language
  for lang, _ in pairs(M.opts.languages) do
    vim.cmd(string.format([[
      augroup SyntaxTract_%s
        autocmd!
        autocmd BufReadPost,BufWritePost *.%s lua require('syntax-tract').conceal_words_and_braces(0, '%s')
        autocmd CursorMoved *.%s lua require('syntax-tract').reveal_line_and_braces(0, vim.fn.line('.') - 1)
        autocmd CursorMoved *.%s lua require('syntax-tract').conceal_words_and_braces(0, '%s')
      augroup END
    ]], lang, lang, lang, lang, lang, lang))
  end
end

return M

