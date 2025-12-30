using Lit

@once mutable struct SessionData
    app_reruns::Int
    fragment_reruns::Int
end

@session_startup begin
    session = SessionData(0, 0)
    set_session_data(session)
end

session = get_session_data()
button("Outside Button")
session.app_reruns += 1
text("App reruns: $(session.app_reruns)")

@fragment begin
    session = get_session_data()
    button("Inside Button")
    session.fragment_reruns += 1
    text("Fragment reruns: $(session.fragment_reruns)")
end

