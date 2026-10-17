
let actions = [];
let nextAction = 0;

actions.push(() => {
    DD_GetElements("dd-button")[0].click();
});

actions.push(() => {
    DD_GetElements("dd-popup dd-button")[0].click();
});

actions.push(() => {
    DD_GetElements("dd-button")[1].click();
});

actions.push(() => {
    setTimeout(() => {
        DD_GetElements("dd-button")[2].click();
    }, 2500);
});

actions.push(() => {
    setTimeout(() => {
        DD_GetElements("dd-popup dd-button")[0].click();
    }, 4000);
});

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
            }
        }

        requestAnimationFrame(() => {
            requestAnimationFrame(() => {
                if (DD_GetElements("dd-checkbox")[0].checked && DD_GetElements("dd-checkbox")[1].checked && DD_GetElements("dd-checkbox")[2].checked) {
                    if (params.has('chromium_instance')) {
                        magic.disconnect("test_done");
                    }
                }
            });
        });
    }
}

magic.setEventListener(eventListener);
