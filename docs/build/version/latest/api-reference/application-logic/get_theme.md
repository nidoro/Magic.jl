# get_theme

Returns the theme of the current session. This is the theme last set by [`set_theme()`](/docs/version/latest/api-reference/application-logic/set_theme). If it was not called in this session, it is the theme cached in the user's browser or, if there is none, the default theme of the page the session was opened on.

Inside dry runs there is no browser, so this function returns `"auto"`.

### Function Signature

```julia
function get_theme()::String
```

### Return Value

A `String` with the theme of the current session: `"auto"`, `"light"` or `"dark"`. Note that `"auto"` is returned as is, regardless of which theme the user's system prefers.

## See also

  * [`set_theme`](/docs/version/latest/api-reference/application-logic/set_theme)
  * [`set_default_theme`](/docs/version/latest/api-reference/application-logic/set_title#setdefaulttheme)
