return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      local is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

      local function find_project_root(extensions)
        local current_dir = vim.fn.expand("%:p:h")
        local root_pattern = is_windows and "^[A-Z]:\\$" or "^/$"

        while current_dir and not current_dir:match(root_pattern) and current_dir ~= "" do
          for _, ext in ipairs(extensions) do
            local matches = vim.fn.glob(current_dir .. "/*" .. ext, true, true)
            if #matches > 0 then
              return current_dir
            end
          end
          current_dir = vim.fn.fnamemodify(current_dir, ":h")
        end
        return nil
      end

      local function run_project_command()
        local filetype = vim.bo.filetype
        local file = vim.fn.expand("%")
        local base_cmd = nil

        if filetype == "cs" or filetype == "fsharp" then
          local root = find_project_root({ ".csproj", ".fsproj" })
          if root then
            base_cmd = "dotnet run --project " .. root
          else
            base_cmd = "dotnet run"
          end
        elseif filetype == "python" then
          base_cmd = (is_windows and "python " or "python3 ") .. file
        elseif filetype == "javascript" then
          base_cmd = "node " .. file
        elseif filetype == "typescript" then
          local root = find_project_root({ "package.json" })
          if root then
            if is_windows then
              base_cmd = "cd " .. root .. " && ts-node " .. file .. " || npx ts-node " .. file
            else
              base_cmd = "cd " .. root .. " && (ts-node " .. file .. " || npx ts-node " .. file .. ")"
            end
          else
            base_cmd = is_windows and ("ts-node " .. file .. " || npx ts-node " .. file)
              or ("(ts-node " .. file .. " || npx ts-node " .. file .. ")")
          end
        elseif filetype == "cpp" or filetype == "c" then
          local lines = vim.api.nvim_buf_get_lines(0, 0, 30, false)
          local has_sfml = false
          for _, line in ipairs(lines) do
            if line:match("#include <SFML/") then
              has_sfml = true
              break
            end
          end

          local exec = is_windows and "app.exe" or "./app"
          if has_sfml then
            base_cmd = "g++ " .. file .. " -o app -lsfml-graphics -lsfml-window -lsfml-system && " .. exec
          else
            base_cmd = "g++ " .. file .. " -o app && " .. exec
          end
        end

        if base_cmd then
          if is_windows then
            return {
              "cmd.exe",
              "/c",
              base_cmd .. " & echo. & pause",
            }
          else
            return {
              "sh",
              "-c",
              "(" .. base_cmd .. ') ; echo; echo "Program finished. Press Enter to close..."; read dummy_var',
            }
          end
        end

        return nil
      end

      _G.run_project_command_shared = run_project_command

      local function launch_interactive_term(cmd_table)
        vim.cmd("w")
        require("snacks").terminal.open(cmd_table, {
          win = { position = "float" },
          kill = true,
        })

        vim.schedule(function()
          local bufnr = vim.api.nvim_get_current_buf()
          if vim.bo[bufnr].buftype == "terminal" then
            vim.keymap.set("t", "<C-c>", "<C-c>", { buffer = bufnr, nowait = true })
            vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { buffer = bufnr, nowait = true })
            vim.cmd("startinsert")
          end
        end)
      end

      _G.launch_interactive_term_shared = launch_interactive_term

      table.insert(opts.sections.lualine_x, 1, {
        function()
          return _G.run_project_command_shared() and "▶ Run" or ""
        end,
        color = { fg = "#ff9e3b", gui = "bold" },
        on_click = function()
          local cmd_table = _G.run_project_command_shared()
          if cmd_table then
            _G.launch_interactive_term_shared(cmd_table)
          else
            print("Unknown filetype for runner execution.")
          end
        end,
      })
    end,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      keys = {
        {
          "<F5>",
          function()
            if _G.run_project_command_shared and _G.launch_interactive_term_shared then
              local cmd_table = _G.run_project_command_shared()
              if cmd_table then
                _G.launch_interactive_term_shared(cmd_table)
              else
                print("Unknown filetype for runner execution.")
              end
            else
              print("Runner utilities not yet loaded by Lualine.")
            end
          end,
          desc = "Run Project with Shared Root Detection",
        },
      },
    },
  },
}
