
let actions = [];
let nextAction = 0;

for (let i = 0; i < 5; i++) {
    actions.push(() => {
        DD_GetElement("dd-button").click();
    });
}

actions.push(() => {
    for (let i = 0; i < 15; i++) {
        DD_GetElement("dd-button").click();
    }
});

for (let i = 0; i < 10; i++) {
    actions.push(() => {
        DD_GetElement("dd-button").click();
    });
}

function eventListener(event) {
    if (event.type == "rerun_complete") {
        if (nextAction < actions.length) {
            actions[nextAction]();
            nextAction += 1;
        } else if (!magic.waitingRerun()) {
            magic.disconnect("test_done");
        }
    }
}

magic.setEventListener(eventListener);
