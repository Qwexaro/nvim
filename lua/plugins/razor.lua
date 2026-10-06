return {
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor", "cshtml" },
    opts = {},
    config = function(_, opts)
      require("roslyn").setup(opts)

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = vim.lsp.get_client_by_id(args.data.client_id)

          if client and client.name == "roslyn" then
            local bufopts = { buffer = bufnr, silent = true }
            vim.keymap.set(
              "n",
              "gd",
              vim.lsp.buf.definition,
              vim.tbl_extend("force", bufopts, { desc = "LSP: Перейти к коду" })
            )
            vim.keymap.set(
              "n",
              "K",
              vim.lsp.buf.hover,
              vim.tbl_extend("force", bufopts, { desc = "LSP: Информация" })
            )
          end
        end,
      })
    end,
  },
}
