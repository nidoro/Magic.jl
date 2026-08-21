
let actions = [];
let nextAction = 0;



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
