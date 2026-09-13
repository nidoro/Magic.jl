---
sidebar_position: 12
---

# get*dot*magic_dir

Returns the location of the app's [`.Magic` directory](/docs/build/docs/getting-started/basic-concepts#the-magic-directory). By default, the .Magic directory is created in the process working directory, but this can be changed in the call to `start_app()` or via the command line.

### Function Signature

```julia
function get_dot_magic_dir()::String
```
