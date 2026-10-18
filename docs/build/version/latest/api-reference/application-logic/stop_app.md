# stop_app

Requests the application server to stop. Once the server stops, the call to [`start_app()`](/docs/version/latest/api-reference/application-logic/start_app) that started it returns.

The request is asynchronous: `stop_app()` returns immediately, before the server has actually stopped.

### Function Signature

```julia
function stop_app()
```
