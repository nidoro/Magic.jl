
let actions = [];
let nextAction = 0;

actions.push(async () => {
    const file = await urlToFile('/images/liberty.jpg', 'liberty.jpg', 'image/jpeg');
    setFileInput(DD_GetElements("dd-file-uploader")[0], file);
});

actions.push(() => {
    DD_GetElements("dd-button")[2].click();
});

function setFileInput(elem, file) {
    const dataTransfer = new DataTransfer();
    dataTransfer.items.add(file);
    elem.input.files = dataTransfer.files;
    elem.input.dispatchEvent(new Event('change', { bubbles: true }));
}

async function urlToFile(url, filename, mimeType) {
    const response = await fetch(url);
    const blob = await response.blob();
    return new File([blob], filename, { type: mimeType });
}

function changeInput(elem, newValue) {
    elem.input.value = newValue
    elem.input.dispatchEvent(new Event('change', { bubbles: true }));
}

function dispatchMouseEventAtRelativePosition(element, type, xRel, yRel) {
    const rect = element.getBoundingClientRect();
    const x = rect.left + rect.width * xRel;
    const y = rect.top + rect.height * yRel;
    const target = document.elementFromPoint(x, y) || element;

    target.dispatchEvent(
        new MouseEvent(type, {
            bubbles: true,
            cancelable: true,
            view: window,
            clientX: x,
            clientY: y,
            button: 0,
            buttons: type === "mouseup" ? 0 : 1,
        })
    );
}

function slideSlider(elem, a, b) {
    dispatchMouseEventAtRelativePosition(elem, "mousedown", a, 0.5);
    requestAnimationFrame(() => {
        dispatchMouseEventAtRelativePosition(elem, "mousemove", b, 0.5);
        requestAnimationFrame(() => {
            dispatchMouseEventAtRelativePosition(elem, "mouseup", b, 0.5);
        });
    });
}

function eventListener(event) {
    const params = new URLSearchParams(window.location.search);

    if (event.type == "rerun_complete") {
        if (!magic.waitingRerun()) {
            if (nextAction < actions.length) {
                requestAnimationFrame(() => {
                    requestAnimationFrame(() => {
                        actions[nextAction]();
                        nextAction += 1;
                    });
                });
            } else if (params.has('chromium_instance')) {
                magic.disconnect("test_done");
            }
        }
    }
}

magic.setEventListener(eventListener);
