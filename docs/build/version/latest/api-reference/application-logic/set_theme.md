# set_theme

Sets the theme of the current session. The new theme is applied once the current rerun finishes, and it persists across reruns until it is changed again.

Each session starts with the default theme of the page it was opened on, which can be configured with [`set_default_theme()`](/docs/version/latest/api-reference/application-logic/set_title#setdefaulttheme).

### Function Signature

```julia
function set_theme(theme::AbstractString)::Nothing
```

| Argument | Description                                                                                                                         |
|:-------- |:----------------------------------------------------------------------------------------------------------------------------------- |
| `theme`  | `String` specifying the theme. Possible values: `"auto"` (follows the theme preferred by the user's system), `"light"` or `"dark"`. |

### Example

```julia
using Magic

theme = radio("Theme", ["auto", "light", "dark"], horizontal=true)
set_theme(theme)
```

## See also

  * [`get_theme`](/docs/version/latest/api-reference/application-logic/get_theme)
  * [`set_default_theme`](/docs/version/latest/api-reference/application-logic/set_title#setdefaulttheme)
