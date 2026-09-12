---
sidebar_position: 15
---

# text

Display a text.

### Function Signature

```julia
function text(anything::Any)::Nothing
```

| Argument | Description                                                                                                                                             |
|:-------- |:------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `text`   | The content to be displayed. If the value is a `AbstractString`, it is rendered as-is. Otherwise, its string representation is obtained using `repr()`. |

### Return Value

Nothing.
