using Magic
using Images
using ImageIO
using ImageFiltering
using ImageEdgeDetection
using Colors

mutable struct Session
    input_img::Union{UploadedFile, Nothing}
end

@session_startup begin
    session = Session(nothing)
    set_session_data(session)

    set_default_value("slc_filter", "Sobel")
end

function upl_image()
    session = get_session_data()
    session.input_img = get_value("upl_image")
end

session = get_session_data()

h1("Image Filters")

cols = columns(2, justify_content="flex-end")

cols(1) do
    file_uploader("Upload image", types=["image/*"], fill_width=true, onchange=upl_image, id="upl_image")
end

if session.input_img !== nothing
    cols(2) do
        selectbox("Filter", ["Sobel"], id="slc_filter")
    end

    cols = columns(2)

    cols(1) do
        column(fill_width=true, align_items="flex-end") do
            image(session.input_img.path)
        end
    end

    cols(2) do
        img = load(session.input_img.path)
        result = nothing

        if get_value("slc_filter") == "Sobel"
            gray_img = Gray.(img)

            gx = imfilter(gray_img, Kernel.sobel()[1])
            gy = imfilter(gray_img, Kernel.sobel()[2])

            gradient_magnitude = sqrt.(gx.^2 .+ gy.^2)
            normalized = gradient_magnitude ./ maximum(gradient_magnitude)

            # Apply contrast enhancement
            enhanced = normalized .* 2

            # Clamp to [0, 1] range
            result = clamp01nan.(enhanced)
        end

        serveable_path = gen_serveable_path(session.input_img.extension)
        save(serveable_path, result)
        image(serveable_path)
    end
end
