local M = {}

local config = {
  wayland = nil,
}

function M.setup(user_config)
  user_config = user_config or {}
  for k, v in pairs(user_config) do
    if config[k] ~= nil then
      config[k] = v
    end
  end
end

local function parse_cloudinary_url(cloudinary_url)
  local pattern = "cloudinary://([^:]+):([^@]+)@([^/]+)"
  local api_key, api_secret, cloud_name = cloudinary_url:match(pattern)
  return api_key, api_secret, cloud_name
end

local function get_clipboard_command(action)
  local session_type
  if config.wayland ~= nil then
    session_type = config.wayland and "wayland" or "x11"
  else
    session_type = os.getenv("XDG_SESSION_TYPE") or "wayland"
  end
  local commands = {
    wayland = { copy = "wl-copy", paste = "wl-paste --type image/png" },
    x11 = { copy = "xclip -selection clipboard", paste = "xclip -selection clipboard -t image/png -o" },
  }
  return commands[session_type][action]
end

local function upload_to_cloudinary(file_path)
  local cloudinary_url = os.getenv("CLOUDINARY_URL")
  if not cloudinary_url then
    vim.notify("CLOUDINARY_URL environment variable not set.", vim.log.levels.ERROR)
    return
  end

  local api_key, api_secret, cloud_name = parse_cloudinary_url(cloudinary_url)
  if not (api_key and api_secret and cloud_name) then
    vim.notify("Invalid CLOUDINARY_URL format.", vim.log.levels.ERROR)
    return
  end

  -- Prepare the payload for the signature
  local timestamp = os.time()
  local signature_payload = "timestamp=" .. timestamp .. api_secret
  local signature = vim.fn.sha256(signature_payload)

  -- Construct the curl command with the silent flag
  local curl_command = string.format(
    "curl --silent --show-error -X POST https://api.cloudinary.com/v1_1/%s/image/upload "
      .. '-F "file=@%s" '
      .. '-F "api_key=%s" '
      .. '-F "timestamp=%s" '
      .. '-F "signature=%s" ',
    cloud_name,
    file_path,
    api_key,
    timestamp,
    signature
  )

  local handle = io.popen(curl_command, "r")
  if not handle then
    vim.notify("Failed to execute curl.", vim.log.levels.ERROR)
    return
  end

  local response = handle:read("*a")
  handle:close()

  if not response or response == "" then
    vim.notify("Received empty response from Cloudinary.", vim.log.levels.ERROR)
    return
  end

  local result = vim.fn.json_decode(response)
  if not result or not result.secure_url then
    vim.notify("Failed to upload image to Cloudinary.", vim.log.levels.ERROR)
    return
  end
  vim.fn.setreg("+", result.secure_url)
  vim.notify("Uploaded image URL: " .. result.secure_url .. " (copied to clipboard)", vim.log.levels.INFO)
end

M.CloudyPaste = function()
  -- Get the directory of the current script
  local script_dir = debug.getinfo(1).source:match("@?(.*/)")
  script_dir = script_dir or "./" -- Use current directory if script_dir is nil
  -- Run clipboard paste command to get clipboard contents (binary data)
  local paste_command = get_clipboard_command("paste")
  local handle = io.popen(paste_command .. " --type image/png", "r")
  if not handle then
    vim.notify("Failed to run clipboard paste command", vim.log.levels.ERROR)
    return
  end

  local image_data = handle:read("*a")
  handle:close()
  if not image_data or #image_data == 0 then
    vim.notify("No image data found in clipboard", vim.log.levels.WARN)
    return
  end

  local file_path = script_dir .. "output.png"
  local file = io.open(file_path, "wb")
  if not file then
    vim.notify("Failed to open file for writing at " .. file_path, vim.log.levels.ERROR)
    return
  end

  file:write(image_data)
  file:close()
  vim.notify("Image saved locally, starting upload to Cloudinary...", vim.log.levels.INFO)
  upload_to_cloudinary(file_path)
end

return M
