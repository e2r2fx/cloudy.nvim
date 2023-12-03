# Cloudy

<p align="center">
  <img src="https://res.cloudinary.com/e2r2fx/image/upload/c_fit,h_200,w_200/v1701644578/tdfwqaud5jppgint6t1k.png" alt="Centered Image">
</p>

Cloudy is a Neovim plugin that simplifies the process of uploading images from your clipboard to Cloudinary. With cloudy, you can directly upload any image you've copied to Cloudinary and automatically receive a link to the uploaded image.

## Features

- Easy uploading of images from clipboard to Cloudinary.
- Automatic copying of the Cloudinary image URL back to clipboard after upload.

## Usage

To use cloudy, ensure you have set your Cloudinary URL in the environment variable `CLOUDINARY_URL`.

```bash
export CLOUDINARY_URL=cloudinary://API_KEY:API_SECRET@CLOUD_NAME
```

In Neovim, simply use the command:

```vim
:CloudyPaste
```

## Requirements

- Neovim (version 0.5 or later)
- wl-clipboard for Wayland clipboard management
- curl for making HTTP requests

## Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your new features or fixes.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
