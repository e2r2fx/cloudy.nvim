vim.api.nvim_create_user_command("CloudyPaste", function()
  require("cloudy").CloudyPaste()
end, {})
