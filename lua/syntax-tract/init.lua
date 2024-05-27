
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
    local ns_id = vim.api.nvim_create_namespace("syntax_tract_words")
    local hl_group = "SyntaxTractConcealed_" .. lang
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    for linenr, line in ipairs(lines) do
      for word, symbol in pairs(lang_opts.words) do
        -- Escape special characters
        local escaped_word = word:gsub("([.*+?^$()%%{}|[\\]])", "%%%1")
        -- Use Lua's pattern matching to find the word
        local start_pos, end_pos = string.find(line, escaped_word)
        while start_pos do
          vim.api.nvim_buf_set_extmark(bufnr, ns_id, linenr-1, start_pos-1, {
            end_col = end_pos,
            conceal = "",
            virt_text = {{symbol, hl_group}},
            virt_text_pos = "overlay",
            hl_group = hl_group,
          })
          start_pos, end_pos = string.find(line, escaped_word, end_pos + 1)
        end
      end
    end
  end

  -- Function to conceal braces
  M.conceal_braces = function(bufnr, lang)
    local lang_opts = M.opts.languages[lang]
    if not lang_opts or not lang_opts.hide_braces then
      return
    end
    local ns_id = vim.api.nvim_create_namespace("syntax_tract_braces")
    local hl_group = "SyntaxTractConcealed_" .. lang
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

    local brace_stack = {}
    local brace_pairs = {}

    for linenr, line in ipairs(lines) do
      local pos = 1
      local indentation = #line:match("^%s*") -- Calculate indentation level
      while pos <= #line do
        local start_pos, end_pos = string.find(line, "[{}]", pos)
        if not start_pos then break end
        local brace_char = line:sub(start_pos, start_pos)
        if brace_char == "{" then
          table.insert(brace_stack, { linenr = linenr - 1, col = start_pos - 1, indent = indentation })
        elseif brace_char == "}" and #brace_stack > 0 then
          local open_brace = brace_stack[#brace_stack]
          if open_brace.indent == indentation then
            table.remove(brace_stack)
            table.insert(brace_pairs, {
              open = open_brace,
              close = { linenr = linenr - 1, col = start_pos - 1 }
            })
          end
        end
        pos = end_pos + 1
      end
    end

    for _, pair in ipairs(brace_pairs) do
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

    -- Save brace pairs in the buffer for later use
    vim.b[bufnr].brace_pairs = brace_pairs
  end

  -- Function to reveal braces within a scope
  M.reveal_braces = function(bufnr, line_nr)
    local ns_id = vim.api.nvim_create_namespace("syntax_tract_braces")
    local brace_pairs = vim.b[bufnr].brace_pairs or {}
    for _, pair in ipairs(brace_pairs) do
      if line_nr >= pair.open.linenr and line_nr <= pair.close.linenr then
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, pair.open.linenr, pair.open.linenr + 1)
        vim.api.nvim_buf_clear_namespace(bufnr, ns_id, pair.close.linenr, pair.close.linenr + 1)
      end
    end
  end

  -- Function to handle CursorMoved event
  M.handle_cursor_moved = function(bufnr)
    local line_nr = vim.fn.line('.') - 1

    M.conceal_words(bufnr, vim.bo[bufnr].filetype)
    vim.api.nvim_buf_clear_namespace(bufnr, vim.api.nvim_create_namespace("syntax_tract_words"), line_nr, line_nr + 1)

    M.conceal_braces(bufnr, vim.bo[bufnr].filetype)
    M.reveal_braces(bufnr, line_nr)
  end

  -- Setup autocommands for each language
  for lang, _ in pairs(M.opts.languages) do
    vim.cmd(string.format([[
      augroup SyntaxTract_%s
        autocmd!
        autocmd BufReadPost,BufWritePost *.%s lua require('syntax-tract').conceal_words(0, '%s')
        autocmd BufReadPost,BufWritePost *.%s lua require('syntax-tract').conceal_braces(0, '%s')
        autocmd CursorMoved *.%s lua require('syntax-tract').handle_cursor_moved(0)
      augroup END
    ]], lang, lang, lang, lang, lang, lang))
  end
end

return M

