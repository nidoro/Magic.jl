# Misc constants
#-------------------
const KiB = 1024
const MiB = 1024*KiB
const GiB = 1024*MiB

const MG_SESSION_ID_SIZE = 32-1
const MG_WIDGET_ID_MAX_SIZE = 256-1
const MG_PATH_MAX = 4096-1

const DOT_MAGIC_GITIGNORE = """.cache-bust
.ssi-parsed

certs
served-files/generated
uploaded-files
companion-host.json
data/
"""

const VERSION = VersionNumber(TOML.parsefile(joinpath(pkgdir(@__MODULE__), "Project.toml"))["version"])

# Widget
#-----------------
const WidgetKind                = Int
const WidgetKind_None           = 0
const WidgetKind_Button         = 1
const WidgetKind_Selectbox      = 2
const WidgetKind_Checkboxes     = 3
const WidgetKind_Radio          = 4
const WidgetKind_Image          = 5
const WidgetKind_DataFrame      = 6
const WidgetKind_TextInput      = 7
const WidgetKind_NumberInput    = 8
const WidgetKind_ColorPicker    = 9
const WidgetKind_Code           = 10
const WidgetKind_FileUploader   = 11
const WidgetKind_Slider         = 12

@with_kw mutable struct Widget
    id          ::String                    = ""
    user_id     ::Union{String, Nothing}    = nothing
    kind        ::WidgetKind                = WidgetKind_None
    clicked     ::Bool                      = false
    value       ::Any                       = nothing
    changes     ::Dict{Int, Dict{String, Any}} = Dict{Int, Dict{String, Any}}()
    alive       ::Bool                      = true
    fragment_id ::String                    = ""

    onclick     ::Function                  = (args...; kwargs...)->()
    onchange    ::Function                  = (args...; kwargs...)->()
    args        ::Vector                    = Vector()

    props::Dict = Dict()
end

# Container stuff
#-------------------
@with_kw mutable struct ContainerInterface
    container       ::Union{Dict, Nothing} = nothing

    columns         ::Function = (args...; kwargs...)->()
    column          ::Function = (args...; kwargs...)->()
    row             ::Function = (args...; kwargs...)->()
    button          ::Function = (args...; kwargs...)->()
    download_button ::Function = (args...; kwargs...)->()
    image           ::Function = (args...; kwargs...)->()
    html            ::Function = (args...; kwargs...)->()
    h1              ::Function = (args...; kwargs...)->()
    h2              ::Function = (args...; kwargs...)->()
    h3              ::Function = (args...; kwargs...)->()
    h4              ::Function = (args...; kwargs...)->()
    h5              ::Function = (args...; kwargs...)->()
    h6              ::Function = (args...; kwargs...)->()
    dataframe       ::Function = (args...; kwargs...)->()
    checkbox        ::Function = (args...; kwargs...)->()
    checkboxes      ::Function = (args...; kwargs...)->()
    selectbox       ::Function = (args...; kwargs...)->()
    radio           ::Function = (args...; kwargs...)->()
    file_uploader   ::Function = (args...; kwargs...)->()
    text_input      ::Function = (args...; kwargs...)->()
    link            ::Function = (args...; kwargs...)->()
    color_picker    ::Function = (args...; kwargs...)->()
    text            ::Function = (args...; kwargs...)->()
    metric          ::Function = (args...; kwargs...)->()
    code            ::Function = (args...; kwargs...)->()
    icon            ::Function = (args...; kwargs...)->()
    space           ::Function = (args...; kwargs...)->()
end

CONTAINER_INTERFACE_FUNCS = [
    :columns, :column, :row, :button, :download_button, :image, :html, :radio, :selectbox,
    :h1, :h2, :h3, :h4, :h5, :h6, :dataframe, :checkbox, :checkboxes,
    :file_uploader, :text_input, :link, :color_picker, :text, :metric, :code,
    :icon, :space
    ]

@with_kw mutable struct Containers
    containers      ::Vector{Union{ContainerInterface, Nothing}} = Vector{Union{ContainerInterface, Nothing}}()

    main_area       ::Union{ContainerInterface, Nothing} = nothing
    left_sidebar    ::Union{ContainerInterface, Nothing} = nothing
    right_sidebar   ::Union{ContainerInterface, Nothing} = nothing
end

Base.getindex(containers::Containers, i) = containers.containers[i]

# Fragment
#-----------------------
@with_kw mutable struct Fragment
    id              ::String   = ""
    func            ::Function = ()->()
    container_props ::Dict     = Dict()
end

# PageConfig
#---------------------
@with_kw mutable struct PageConfig
    id              ::String = ""
    uris            ::Vector{String} = Vector{String}()
    title           ::String = "Magic App"
    description     ::String = "Web app made with Magic.jl"
    style           ::String = ""
    file_path       ::String = ""
    html_injection  ::Dict{String, String} = Dict()
    first_pass      ::Bool   = true
    user_page_data  ::Any    = nothing

    set_title       ::Function = (args...; kwargs...)->()
    set_description ::Function = (args...; kwargs...)->()
    add_font        ::Function = (args...; kwargs...)->()
    add_css_rule    ::Function = (args...; kwargs...)->()
end

# AppTask
#------------
@with_kw mutable struct AppTask
    task            ::Union{Task, Nothing}  = nothing
    client_id       ::Cint                  = 0
    session         ::Any                   = nothing
    state           ::Dict{String, Any}     = Dict{String, Any}()
    container_stack ::Vector{ContainerInterface} = Vector{ContainerInterface}()
    fragment_stack  ::Vector{Fragment}      = Vector{Fragment}()
    payload         ::Dict                  = Dict()
    current_page    ::PageConfig            = PageConfig()
    layout          ::Containers            = Containers()
end

# NetEvent
#---------------
const NetEventType                       = Cint
const NetEventType_None                  = Cint(0)
const NetEventType_ServerReady           = Cint(1)
const NetEventType_NewClient             = Cint(2)
const NetEventType_ClientLeft            = Cint(3)
const NetEventType_NewPayload            = Cint(4)
const NetEventType_ServerLoopInterrupted = Cint(5)

@with_kw mutable struct NetEvent
    ev_type         ::NetEventType  = NetEventType_None
    client_id       ::Cint          = 0
    session_id      ::NTuple{MG_SESSION_ID_SIZE+1, UInt8} = ntuple(_ -> 0x00, MG_SESSION_ID_SIZE+1)
    payload         ::Ptr{Cchar}    = Ptr{Cchar}(0)
    payload_size    ::Cint          = 0
end

# AppEvent
#--------------
const AppEventType                      = Cint
const AppEventType_None                 = Cint(0)
const AppEventType_NewPayload           = Cint(1)
const AppEventType_DownloadReady        = Cint(2)
const AppEventType_ServerStopRequested  = Cint(3)
const AppEventType_FatalError           = Cint(4)
const AppEventType_DisconnectRequested  = Cint(5)

@with_kw mutable struct AppEvent
    ev_type         ::AppEventType  = AppEventType_None
    client_id       ::Cint          = 0
    payload         ::Ptr{Cchar}    = Ptr{Cchar}(0)
    payload_size    ::Cint          = 0
    download_path   ::NTuple{MG_PATH_MAX+1, UInt8} = ntuple(_ -> 0x00, MG_PATH_MAX+1)
end

# InternalEvent
#-------------------
const InternalEventType          = Cint
const InternalEventType_None     = Cint(0)
const InternalEventType_Network  = Cint(1)
const InternalEventType_Task     = Cint(2)

@with_kw mutable struct InternalEvent
    ev_type ::InternalEventType         = InternalEventType_None
    data    ::Union{NetEvent, AppTask}  = Union{NetEvent, AppTask}()
end

# CallbackReason
#--------------------
@enum CallbackReason begin
    CallbackReason_ServerReady
    CallbackReason_NewClient
    CallbackReason_BeforeSessionFirstPass
    CallbackReason_AfterSessionFirstPass
    CallbackReason_ClientLeft
    CallbackReason_NewPayload
    CallbackReason_TaskFinished
    CallbackReason_ClientSideError
    CallbackReason_DisconnectRequested
end

# Session
#-------------
@with_kw mutable struct RerunRequest
    payload::Dict = Dict()
end

@with_kw struct RerunError
    message     ::String = ""
    stacktrace  ::String = ""
end

@with_kw mutable struct Session
    client_id                   ::Cint                      = 0
    session_id                  ::String                    = ""
    widgets                     ::Dict{String, Widget}      = Dict{String, Widget}()
    fragments                   ::Dict{String, Fragment}    = Dict{String, Fragment}()
    location                    ::Dict                      = Dict()
    user_session_data           ::Any                       = nothing
    first_pass                  ::Bool                      = true
    widget_defaults             ::Dict{String, Any}         = Dict{String, Any}()
    rerun_task                  ::Union{Task, Nothing}      = nothing
    rerun_queue                 ::Vector{RerunRequest}      = Vector{RerunRequest}()
    waiting_invalid_state_ack   ::Bool                      = false
    client_left                 ::Bool                      = false
    rerun_error                 ::Union{RerunError, Nothing} = nothing
    refresh                     ::Bool                      = false
    app_mod                     ::Module                    = Module(:MagicApp)
end

# Global
#------------
@with_kw mutable struct Global
    initialized         ::Bool                      = false
    dot_magic_dir       ::String                    = ""
    script_or_func      ::Union{String, Function}   = "app.jl"
    script_name         ::Union{String, Nothing}    = nothing
    host_name           ::String                    = ""
    port                ::Int                       = 3443
    sessions            ::Dict{Cint, Session}       = Dict{Ptr{Cvoid}, Session}()
    fd_read             ::Int32                     = -1
    fd_write            ::Int32                     = -1
    internal_events     ::Channel{InternalEvent}    = Channel{InternalEvent}(1024)
    user_app_data       ::Any                       = nothing
    first_pass          ::Bool                      = true
    base_page_config    ::PageConfig                = PageConfig()
    pages               ::Vector{PageConfig}        = Vector{PageConfig}()
    verbose             ::Bool                      = false
    dev_mode            ::Bool                      = false
    ipc_connection      ::Union{TCPSocket, Nothing} = nothing
    dry_run_error       ::Union{RerunError, Nothing} = nothing
    upload_max_size     ::Int                       = 25*MiB
    upload_max_files    ::Int                       = 10
    test_successfull    ::Bool                      = false

    callback            ::Union{Function, Nothing}  = nothing
    MAGIC_SO            ::String                    = ""
    LIBMAGIC            ::Any                       = nothing
end

# USER_TYPES  = Dict{Symbol,DataType}() # DEPRECATED: for usage with @once

# File uploader
#-----------------
@with_kw mutable struct UploadedFile
    id::String          = ""
    name::String        = ""
    extension::String   = ""
    path::String        = ""
    type::String        = ""
    size::Int           = 0
    last_modified::Int  = 0
end

# Error stuff
#----------------
abstract type MagicError        <: Exception  end
struct InvalidFile              <: MagicError file_path::String end
struct InvalidDirectory         <: MagicError dir_path::String end
struct InvalidHostname          <: MagicError hostname::String end
struct InvalidPort              <: MagicError port::Int end
struct InvalidUploadMaxSize     <: MagicError upload_max_size::Int end
struct InvalidUploadMaxFiles    <: MagicError upload_max_files::Int end
struct ClientSideError          <: MagicError payload::Dict end
struct TestFailed               <: MagicError test_id::String; info::String end

Base.showerror(io::IO, e::InvalidFile)              = print(io, "File not found or invalid: $(e.file_path)")
Base.showerror(io::IO, e::InvalidDirectory)         = print(io, "Directory not found or invalid: $(e.dir_path)")
Base.showerror(io::IO, e::InvalidPort)              = print(io, "Invalid port: $(e.port). Please provide a value between 0 and 65535.")
Base.showerror(io::IO, e::InvalidUploadMaxSize)     = print(io, "Invalid upload max size: $(e.upload_max_size). Please provide a number greater than or equal to 0.")
Base.showerror(io::IO, e::InvalidUploadMaxFiles)    = print(io, "Invalid upload max files: $(e.upload_max_files). Please provide a number greater than or equal to 0.")
Base.showerror(io::IO, e::ClientSideError)          = print(io, "Client side error:\n$(JSON.json(e.payload, 4))")
Base.showerror(io::IO, e::TestFailed)               = print(io, "Test failed: $(e.test_id)\n$(e.info)")

# Colored log utils. AC stands for "ANSI Color"
#------------------------------------------------
const AC_Reset         = "\x1b[0m"
const AC_CodeRed       = "\x1b[31m"
const AC_CodeGreen     = "\x1b[32m"
const AC_CodeYellow    = "\x1b[33m"
const AC_CodeBlue      = "\x1b[34m"
const AC_CodeMagenta   = "\x1b[35m"
const AC_CodeCyan      = "\x1b[36m"

const AC_CodeBold      = "\x1b[1m"
const AC_ResetBold     = "\x1b[22m"

const AC_Red     = (text::String) -> AC_CodeRed     * text * AC_Reset
const AC_Green   = (text::String) -> AC_CodeGreen   * text * AC_Reset
const AC_Yellow  = (text::String) -> AC_CodeYellow  * text * AC_Reset
const AC_Blue    = (text::String) -> AC_CodeBlue    * text * AC_Reset
const AC_Magenta = (text::String) -> AC_CodeMagenta * text * AC_Reset
const AC_Cyan    = (text::String) -> AC_CodeCyan    * text * AC_Reset
const AC_Bold    = (text::String) -> AC_CodeBold    * text * AC_Reset
