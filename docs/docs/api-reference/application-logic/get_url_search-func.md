---
sidebar_position: 17
---

# get_url_search

Returns the search string part of the URL used by the client to access the web app.

> **🛈 NOTE**: This returns the raw search string. If you would like to retrieve


it with query parameters already parsed, check out `get_query_params`.

### Function Signature

```julia
function get_url_search()::String
```

## See also

  * [`get_server_host`](/docs/build/docs/api-reference/application-logic/get_server_host-func)
  * [`get_server_port`](/docs/build/docs/api-reference/application-logic/get_server_port-func)
  * [`get_server_origin`](/docs/build/docs/api-reference/application-logic/get_server_origin-func)
  * [`get_query_params`](/docs/build/docs/api-reference/application-logic/get_query_params-func)
