# syntax-tract.nvim
A neovim plugin to make your code more **readable** through syntax abstractions to hide unnecessary words or patterns. These set patterns will only show up when your cursor is hovering over the line containing the abstraction.

## Installation

For **lazy-nvim** users:
```lua
{
    'RyanBlaney/syntax-tract.nvim',
    opts = {
      languages = {
        cpp = {
          words = {
            --["TO_REPLACE"] = "SYMBOL",
            ["std::"] = "⊇",
            ["\\n"] = "⏎",
            ["%(int%)"] = "⚙",
            ["%(unsigned int%)"] = "⚙",
            ["%(char%)"] = "⚙",
            ["%(float%)"] = "⚙",
            ["%(double%)"] = "⚙",
            ["%(long long%)"] = "⚙",
            ["%(unsigned long long%)"] = "⚙",
            ["%(short%)"] = "⚙",
            ["%(unsigned short%)"] = "⚙",
            ["%(long%)"] = "⚙",
            ["%(unsigned long%)"] = "⚙",
            ["%(bool%)"] = "⚙",
            ["%(wchar_t%)"] = "⚙",
            ["%(unsigned char%)"] = "⚙",
            ["%(signed char%)"] = "⚙",
            ["%(void%*)"] = "⚙",
            ["%(size_t%)"] = "⚙",
            ["%(ptrdiff_t%)"] = "⚙",
            ["%(intptr_t%)"] = "⚙",
            ["%(uintptr_t%)"] = "⚙",
            ["%(std::string%)"] = "⚙",
            ["%(std::wstring%)"] = "⚙",
            ["static_cast<int>"] = "⚙",
            ["static_cast<unsigned int>"] = "⚙",
            ["static_cast<char>"] = "⚙",
            ["static_cast<float>"] = "⚙",
            ["static_cast<double>"] = "⚙",
            ["static_cast<long long>"] = "⚙",
            ["static_cast<unsigned long long>"] = "⚙",
            ["static_cast<short>"] = "⚙",
            ["static_cast<unsigned short>"] = "⚙",
            ["static_cast<long>"] = "⚙",
            ["static_cast<unsigned long>"] = "⚙",
            ["static_cast<bool>"] = "⚙",
            ["static_cast<wchar_t>"] = "⚙",
            ["static_cast<unsigned char>"] = "⚙",
            ["static_cast<signed char>"] = "⚙",
            ["static_cast<void*>"] = "⚙",
            ["static_cast<size_t>"] = "⚙",
            ["static_cast<ptrdiff_t>"] = "⚙",
            ["static_cast<intptr_t>"] = "⚙",
            ["static_cast<uintptr_t>"] = "⚙",
            ["static_cast<std::string>"] = "⚙",
            ["static_cast<std::wstring>"] = "⚙",
          },
          color = "#ff8a8a"
        },
        -- Add more languages here
      }
    }
  }
```


