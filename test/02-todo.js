
let actions = [];
let nextAction = 0;

// Add new items
//------------------
actions.push(() => {
    DD_GetElement("dd-input").input.value = "New item 1";
    DD_GetElement("dd-input").input.dispatchEvent(new Event('change', { bubbles: true }));
});

actions.push(() => {
    DD_GetElements("dd-button")[1].click();
});

actions.push(() => {
    DD_GetElement("dd-input").input.value = "New item 2";
    DD_GetElement("dd-input").input.dispatchEvent(new Event('change', { bubbles: true }));
});

actions.push(() => {
    DD_GetElements("dd-button")[1].click();
});

// Delete multiple items
//-----------------
actions.push(() => {
    DD_GetElements("dd-checkbox")[1].click();
    DD_GetElements("dd-checkbox")[3].click();
});

actions.push(() => {
    DD_GetElements("dd-button")[7].click();
});

// Add new items
//------------------
actions.push(() => {
    DD_GetElement("dd-input").input.value = "New item 3";
    DD_GetElement("dd-input").input.dispatchEvent(new Event('change', { bubbles: true }));
});

actions.push(() => {
    DD_GetElements("dd-button")[1].click();
});

actions.push(() => {
    DD_GetElement("dd-input").input.value = "New item 4";
    DD_GetElement("dd-input").input.dispatchEvent(new Event('change', { bubbles: true }));
});

actions.push(() => {
    DD_GetElements("dd-button")[1].click();
});

// Delete individual items
//---------------------------
actions.push(() => {
    DD_GetElements("dd-button")[3].click();
});

actions.push(() => {
    DD_GetElements("dd-button")[2].click();
});

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
