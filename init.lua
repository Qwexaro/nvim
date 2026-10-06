-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

require("lspconfig").omnisharp.setup({
  cmd = { "omnisharp" },
  -- Явно разрешаем запуск ТОЛЬКО в файлах C#
  filetypes = { "cs", "vb" },
  root_dir = require("lspconfig").util.root_pattern("*.sln", "*.csproj", ".git"),
  -- ваши остальные настройки...
})

vim.filetype.add({
  extension = {
    cshtml = "razor",
    razor = "razor",
  },
})
