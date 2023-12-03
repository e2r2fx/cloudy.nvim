local M = {}

local function parse_cloudinary_url(cloudinary_url)
  local pattern = "cloudinary://([^:]+):([^@]+)@([^/]+)"
  local api_key, api_secret, cloud_name = cloudinary_url:match(pattern)
  return api_key, api_secret, cloud_name
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

  -- Execute the curl command
  local handle = io.popen(curl_command, "r")
  if handle then
    local response = handle:read("*a")
    handle:close()

    if response and response ~= "" then
      -- Parse the JSON response
      local result = vim.fn.json_decode(response)
      if result and result.secure_url then
        -- Copy the URL to the clipboard using wl-copy
        local copy_handle = io.popen("wl-copy", "w")
        if copy_handle then
          copy_handle:write(result.secure_url)
          copy_handle:close()
          vim.notify("Uploaded image URL: " .. result.secure_url .. " (copied to clipboard)", vim.log.levels.INFO)
        else
          vim.notify("Failed to copy URL to clipboard.", vim.log.levels.ERROR)
        end
      else
        vim.notify("Failed to upload image to Cloudinary.", vim.log.levels.ERROR)
      end
    else
      vim.notify("Received empty response from Cloudinary.", vim.log.levels.ERROR)
    end
  else
    vim.notify("Failed to execute curl.", vim.log.levels.ERROR)
  end
end

M.CloudyPaste = function()
  -- Run wl-paste to get clipboard contents (binary data)
  local handle = io.popen("wl-paste --type image/png", "r")
  if handle then
    local image_data = handle:read("*a")
    handle:close()

    if image_data and #image_data > 0 then
      local file_path = "/home/e2r2fx/Documents/output.png"
      local file = io.open(file_path, "wb")
      if file then
        file:write(image_data)
        file:close()
        vim.notify("Image saved locally, starting upload to Cloudinary...", vim.log.levels.INFO)
        upload_to_cloudinary(file_path)
      else
        vim.notify("Failed to open file for writing at " .. file_path, vim.log.levels.ERROR)
      end
    else
      vim.notify("No image data found in clipboard", vim.log.levels.WARN)
    end
  else
    vim.notify("Failed to run wl-paste", vim.log.levels.ERROR)
  end
end

return M
