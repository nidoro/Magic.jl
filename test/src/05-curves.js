
let actions = [];
let nextAction = 0;

actions.push(() => {
    slideSlider(DD_GetElements("dd-slider")[0], 0.5, 0.8);
});

actions.push(() => {
    slideSlider(DD_GetElements("dd-slider")[1], 0.1, 0.7);
});

actions.push(() => {
    slideSlider(DD_GetElements("dd-slider")[2], 0.3, 0.4);
});

actions.push(() => {
    slideSlider(DD_GetElements("dd-slider")[3], 0.9, 0.5);
});

actions.push(() => {
    slideSlider(DD_GetElements("dd-slider")[0], 0.5, 0.6);
});

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
        if (nextAction < actions.length) {
            requestAnimationFrame(() => {
                actions[nextAction]();
                nextAction += 1;
            });
        } else if (!magic.waitingRerun() && params.has('chromium_instance')) {
            magic.disconnect("test_done");
        }
    }
}

magic.setEventListener(eventListener);
