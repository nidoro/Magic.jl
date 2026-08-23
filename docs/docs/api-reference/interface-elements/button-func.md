---
sidebar_position: 1
---

# button

Display a button widget.

### Function Signature

```julia
function button(
    label   ::String    ="";
    style   ::String    ="secondary",
    icon    ::String    ="",
    onclick ::Function  =()->(),
    args::Union{Vector, Tuple}=Vector()
)::Bool
```

 Argument  | Description
---------- |-------------
 `label`   | A `String` to be displayed inside the button. It can contain HTML.
 `style`   | A `String` specifying the predefined style to be applied to the button. Possible values: `primary`, `secondary` (default), or `naked`.
 `icon`    | A `String` in the format `material/icon_name`. Example: `material/thumb_up`.<br/><br/>Check out https://fonts.google.com/icons?icon.set=Material+Icons to learn the icon names.
 `onclick` | A callback `Function`. This function will be called when the button is clicked, before the app script is rerun.
 `args`    | A `Vector` of arguments that will be passed to the `onclick` callback function.

### Return Value

`true` if the button was clicked, `false` otherwise.
