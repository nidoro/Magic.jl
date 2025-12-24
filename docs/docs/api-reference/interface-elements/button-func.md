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
    onclick ::Function  =(args...; kwargs...)->(),
    args    ::Vector    =Vector()
)::Bool
```

 Argument  | Description
---------- |-------------
 `label`   | A `String` to be displayed inside the button. It can contain HTML.
 `style`   | A `String`. Should be either `primary`, `secondary`, or `naked`. Default: `secondary`.
 `icon`    | A `String` in the format `material/icon_name`. Example: `material/thumb_up`.<br/><br/>Check out https://fonts.google.com/icons?icon.set=Material+Icons to learn the icon names.
 `onclick` | A callback `Function`. This function will be called when the button is clicked, before the app script is rerun.
 `args`    | A `Vector` of arguments that will be passed to the `onclick` callback function.

### Return Value

`true` if the button was clicked, `false` otherwise.
