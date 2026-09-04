---
sidebar_position: 33
---

# download_button

Creates a download button widget. It behaves similarly to
[`button()`](/docs/build/docs/api-reference/interface-elements/button-func),
but with the additional effect of starting a download.

### Function Signature

```julia
function download_button(
    label       ::String,
    file_path   ::String;
    file_name   ::Union{String, Nothing}    =nothing,
    style       ::String                    ="secondary",
    icon        ::String                    ="material/download",
    onclick     ::Function                  =()->(),
    args        ::Vector                    =Vector()
)::Bool
```

 Argument     | Description
------------------ | -----------
 `label`   | A `String` to be displayed inside the button. It can contain HTML.
 `file_path`    | A `String` specifying the file to be downloaded. The file must live inside `.Magic/served-files/` somewhere. See [The `.Magic` directory](https://magic.coisasdodavi.net/docs/build/docs/getting-started/basic-concepts#the-magic-directory) to learn more.
 `file_name`    | A `String` specifying the name with which the file should be saved in the client side.
 `style`   | A `String`. Should be either `primary`, `secondary`, or `naked`. Default: `secondary`.
 `icon`    | A `String` in the format `material/icon_name`. Example: `material/thumb_up`.<br/><br/>Check out https://fonts.google.com/icons?icon.set=Material+Icons to learn the icon names.
 `onclick` | A callback `Function`. This function will be called when the button is clicked, before the app script is rerun.
 `args`    | A `Vector` of arguments that will be passed to the `onclick` callback function.

### Return Value

`true` if the button was clicked, `false` otherwise.

### Generating downloadable files

The provided `file_path` may or may not point to an existing file.
It can point to a path inside `.Magic/served-files` where the file will be
generated when the download button is clicked. Example:

```julia
serveable_path = gen_serveable_path(".png")
if download_button("Download", serveable_path)
    # Generate file here and save it at `serveable_path`
end
```

Alternatively, you can generate the file within the `onclick` callback. Example:

```julia
function gen_file(path)
    # Generate file here and save it at `path`
end

serveable_path = gen_serveable_path(".png")
download_button("Download", serveable_path, onclick=gen_file, args=[serveable_path])
```

### Example

See [Image Filters Demo](https://magic.coisasdodavi.net/image-filters) for a
`download_button` usage example.

