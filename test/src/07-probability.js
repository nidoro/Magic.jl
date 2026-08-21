
let actions = [];
let nextAction = 0;

actions.push(() => {
    DD_GetElements("dd-input")[0].click();
    requestAnimationFrame(() => {
        DD_GetElements("dd-option")[2].click();
    });
});

actions.push(() => {
    DD_GetElements("dd-button")[3].click();
    requestAnimationFrame(() => {
        DD_GetElements("dd-button")[3].click();
        requestAnimationFrame(() => {
            DD_GetElements("dd-button")[3].click();
        });
    });
});

actions.push(() => {
    DD_GetElements("dd-input")[0].click();
    requestAnimationFrame(() => {
        DD_GetElements("dd-option")[3].click();
    });
});

actions.push(() => {
    requestAnimationFrame(() => {
        changeInput(DD_GetElements("dd-input")[1], 3.5);
    });
});

actions.push(() => {
    DD_GetElements("dd-button")[6].click();
    requestAnimationFrame(() => {
        DD_GetElements("dd-button")[6].click();
    });
});

actions.push(() => {
    DD_GetElements("dd-button")[2].click();
});

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
