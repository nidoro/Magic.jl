---
sidebar_position: 15
---

# First pass functions

Family of `Bool` returning functions:

  * `is_app_first_pass()`: returns `true` it is the first time the app is being

run, and `false` otherwise. See also: [`@app_startup`](/docs/build/docs/api-reference/application-logic/@app_startup-func).

  * `is_page_first_pass()`: returns `true` it is the first time the current page

is being run, and `false` otherwise. See also: [`@page_startup`](/docs/build/docs/api-reference/application-logic/@page_startup-func).

  * `is_session_first_pass()`: returns `true` it is the first time the session

is being run, and `false` otherwise. See also: [`@session_startup`](/docs/build/docs/api-reference/application-logic/@session_startup-func).
