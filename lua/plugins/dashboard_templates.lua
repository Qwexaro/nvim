return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      local function open_template_menu()
        local templates = {
          "C++ (Console Base)",
          "C++ (SFML)",
          "C# (.NET Console base)",
          "C# (.NET ASP Web API Lightweight)",
          "F# (.NET Console Base)",
          "JavaScript (Node.js)",
          "TypeScript (Completed project)",
        }

        vim.ui.select(templates, {
          prompt = "Choice template for new project:",
        }, function(choice)
          if not choice then
            return
          end

          local function check_dep(cmd, install_hint)
            if vim.fn.executable(cmd) == 0 then
              vim.notify("Error: utility '" .. cmd .. "' not found!\n" .. install_hint, vim.log.levels.ERROR)
              return false
            end
            return true
          end

          if choice:match("C%+%+") and not check_dep("g++", "Please, install GCC.") then
            return
          end
          if choice:match("C#") or choice:match("F#") then
            if not check_dep("dotnet", "Please, install .NET SDK.") then
              return
            end
          end
          if choice:match("JavaScript") or choice:match("TypeScript") then
            if not check_dep("node", "Please, install Node.js.") then
              return
            end
            if not check_dep("npm", "Please, install npm.") then
              return
            end
          end

          vim.ui.input({ prompt = "Enter name of project (directory): " }, function(project_name)
            if not project_name or project_name == "" then
              return
            end

            local function write_file(path, content)
              local file = io.open(path, "w")
              if file then
                file:write(content)
                file:close()
              end
            end

            vim.fn.mkdir(project_name, "p")
            local project_path = vim.fn.getcwd() .. "/" .. project_name

            if choice:match("SFML") then
              local cpp_code = [[#include <SFML/Graphics.hpp>
#include <optional>

int main() {
    sf::RenderWindow window(sf::VideoMode({800, 600}), "SFML Project");
    sf::CircleShape shape(100.f);
    shape.setFillColor(sf::Color::Green);

    while (window.isOpen()) {
        while (const std::optional<sf::Event> event = window.pollEvent()) {
            if (event->is<sf::Event::Closed>()) window.close();
        }
        window.clear();
        window.draw(shape);
        window.display();
    }
    return 0;
}]]
              local makefile_code = [[all:
	g++ main.cpp -o app -lsfml-graphics -lsfml-window -lsfml-system

run:
	./app
]]
              write_file(project_path .. "/main.cpp", cpp_code)
              write_file(project_path .. "/Makefile", makefile_code)
              vim.fn.chdir(project_path)
              vim.cmd("edit main.cpp")
            elseif choice:match("Console Base") and choice:match("C%+%+") then
              local base_cpp = [[#include <iostream>

int main() {
    std::cout << "Hello, World!" << std::endl;
    return 0;
}]]
              write_file(project_path .. "/main.cpp", base_cpp)
              vim.fn.chdir(project_path)
              vim.cmd("edit main.cpp")
            elseif choice:match("JavaScript") then
              local js_code = [[// Base script Node.js
console.log("Hello from JavaScript project!");
]]
              write_file(project_path .. "/index.js", js_code)
              vim.fn.chdir(project_path)
              vim.cmd("edit index.js")
            else
              local cmd = ""
              local target_file = ""

              if choice:match("C#") and choice:match("Console") then
                cmd = "dotnet new console"
                target_file = "Program.cs"
              elseif choice:match("Web API") then
                cmd = "dotnet new webapi"
                target_file = "Program.cs"
              elseif choice:match("F#") then
                cmd = "dotnet new console -lang 'F#'"
                target_file = "Program.fs"
              elseif choice:match("TypeScript") then
                -- File generation moved entirely inside on_exit to prevent npm clashing
                cmd = "npm init -y && npm install -D typescript @types/node ts-node && npx tsc --init"
                target_file = "index.ts"
              end

              if cmd ~= "" then
                vim.notify("Pulling template and installing dependencies...", vim.log.levels.INFO)

                vim.fn.jobstart(cmd, {
                  cwd = project_path,
                  on_exit = function(_, exit_code)
                    vim.schedule(function()
                      if exit_code == 0 then
                        vim.fn.chdir(project_path)

                        if choice:match("Web API") then
                          local clean_web_code = [[var builder = WebApplication.CreateBuilder(args);
var app = builder.Build();

app.MapGet("/", () => "Base WEB-App ASP.NET successfully running!");

app.Run();
]]
                          write_file(project_path .. "/Program.cs", clean_web_code)
                        elseif choice:match("TypeScript") then
                          local ts_code = [[// Config TypeScript active
const message: string = "Hello from TypeScript!";
console.log(message);
]]
                          write_file(project_path .. "/index.ts", ts_code)
                        end

                        vim.cmd("edit " .. target_file)
                        vim.notify("Project has been created!", vim.log.levels.INFO)
                      else
                        vim.notify("Error initializing template for project.", vim.log.levels.ERROR)
                      end
                    end)
                  end,
                })
              end
            end
          end)
        end)
      end

      if opts.dashboard and opts.dashboard.preset and opts.dashboard.preset.keys then
        local new_button = {
          icon = "T ",
          key = "t",
          desc = "New Project from Template",
          action = open_template_menu,
        }
        table.insert(opts.dashboard.preset.keys, 2, new_button)
      end
    end,
  },
}
