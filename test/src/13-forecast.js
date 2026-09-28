
let actions = [];
let nextAction = 0;

actions.push(() => {
    requestAnimationFrame(() => {
        dispatchMouseEventAtRelativePosition(DD_GetElements(".tabulator .tabulator-cell")[7], "dblclick", 0.5, 0.5);
        requestAnimationFrame(() => {
            DD_SetValue("input", 30);
            requestAnimationFrame(() => {
                dispatchEnterDownEvent(DD_GetElement("input"));
            });
        });
    });
});

actions.push(() => {
    requestAnimationFrame(() => {
        dispatchMouseEventAtRelativePosition(DD_GetElements(".tabulator .tabulator-cell")[1], "dblclick", 0.5, 0.5);
        requestAnimationFrame(() => {
            DD_SetValue("input", 15);
            requestAnimationFrame(() => {
                dispatchEnterDownEvent(DD_GetElement("input"));
            });
        });
    });
});

function dispatchEnterDownEvent(element) {
    element.dispatchEvent(new KeyboardEvent("keydown", {
        key: "Enter",
        code: "Enter",
        keyCode: 13, // older Tabulator versions check keyCode, newer ones check key
        which: 13,
        bubbles: true,
        cancelable: true,
    }));
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
