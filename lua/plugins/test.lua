return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      table.insert(opts.ensure_installed, "netcoredbg")
    end,
  },

  {
    "nvim-neotest/neotest",
    dependencies = {
      "Issafalcon/neotest-dotnet",
    },
    opts = function(_, opts)
      table.insert(opts.adapters, require("neotest-dotnet")({
        dap = {
          args = { "--interpreter=vscode" },
          runtime_executable = "dotnet",
        },
        dotnet_additional_args = { "--no-build" },
      }))
    end,
  },
}

