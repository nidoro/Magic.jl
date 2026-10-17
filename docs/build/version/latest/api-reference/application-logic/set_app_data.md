# App persistent data

App persistent data is an user defined data whose lifetime is the lifetime of the app, meaning that as long as the app is running the data will persist. App persistent data can be retrieved at any moment using `get_app_data()` and is shared accross pages and sessions.

Although the app persistent data can be either mutable or immutable, a good practice is to define a mutable struct to store all of your app's data and store it with `set_app_data()` at the application startup. Example:

```julia
# Define the struct to hold the app persistent data
mutable struct AppData
    foo::String
    bar::Int
end

@app_startup begin
    # Initialize the app persistent data
    app = AppData("hello", 32)
    set_app_data(app)
end

# now `get_app_data()` can be called from anywhere to retrieve the app data
```

In the example above, since the persistent data is a mutable struct, every time `get_app_data()` is called the same `AppData` object instance stored with `set_app_data()` at the app startup is returned, and thus you can modify its members without having to call `set_app_data()` ever again.

## `set_app_data()`

Stores app persistent data.

### Function Signature

```julia
function set_app_data(app_data::Any)::Nothing
function set_app_data(key::AbstractString, value::Any)::Nothing
```

| Argument   | Description                                                                                                                                                                                 |
|:---------- |:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `app_data` | Data of `Any` type.                                                                                                                                                                         |
| `key`      | A `String` identifying a keyed entry of the app persistent data. Keyed entries are stored separately from the data set with `set_app_data(app_data)`, so both can be used at the same time. |
| `value`    | Data of `Any` type to be stored under `key`.                                                                                                                                                |

## `get_app_data()`

Retrieves the previously stored app persistent data.

### Function Signature

```julia
function get_app_data(key::Union{AbstractString, Nothing}=nothing)::Any
```

| Argument | Description                                                                                                                                                                                                                               |
|:-------- |:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `key`    | An optional `String`. If `nothing` (default), returns the data stored with `set_app_data(app_data)`. Otherwise, returns the data stored under `key` with `set_app_data(key, value)`, or `missing` if no data has been stored under `key`. |
