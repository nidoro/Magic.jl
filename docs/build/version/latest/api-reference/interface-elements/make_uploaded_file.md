# make_uploaded_file

Creates an [`UploadedFile`](/docs/version/latest/api-reference/interface-elements/file_uploader#uploadedfile) from a local file, so it can be handled with the same code that handles files provided via [`file_uploader()`](/docs/version/latest/api-reference/interface-elements/file_uploader).

### Function Signature

```julia
function make_uploaded_file(file_path::String)::UploadedFile
```

| Argument    | Description                                   |
|:----------- |:--------------------------------------------- |
| `file_path` | A `String` with the path of an existing file. |

### Return Value

An `UploadedFile` describing the file. Its `path` field holds the absolute path of the file, and its `name`, `extension`, `type`, `size` and `last_modified` fields are filled in from the file itself.
