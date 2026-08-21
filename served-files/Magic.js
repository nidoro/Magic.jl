const KiB = 1024;
const MiB = 1024*KiB;
const GiB = 1024*MiB;

class Magic {
    constructor() {
        this.eventListener = () => {};
    }

    setEventListener(eventListener) {
        this.eventListener = eventListener;
    }

    requestRerun(events) {
        requestUpdate(events);
    }

    disconnect(reason) {
        wsSendObj({
            type: "disconnect",
            reason: reason,
        });
    }

    getRerunCount() {
        return g.reruns;
    }

    waitingRerun() {
        return g.waitingRerun > 0;
    }
}

class MG_Icon extends HTMLElement {
    constructor() {
        super();
    }

    connectedCallback() {
        const iconId = this.getAttribute("mg-icon");
        const iconName = iconId.split("/")[1];
        if (iconName in g.materialIcons) {
            this.innerHTML = `&#x${g.materialIcons[iconName]};`;
        }
    }
}

const FILE_UPLOADER_DEFAULT_INNER_HTML = `
    <div class="mg-icon-container">
        <mg-icon mg-icon="material/upload"></mg-icon>
    </div>
    <div class="mg-inner-label">
        <p>
            <b>Drag and drop</b> a file here
            or <b>Click</b> to open the file browser
        </p>
    </div>
`;

var magic = new Magic();

var g = {
    ws: null,
    devMode: false,
    nextRequestId: 1,
    lastValidRerunResponse: null,
    sessionId: null,
    uploadMaxSize: null,
    uploadMaxFiles: null,
    reruns: 0,
    waitingRerun: 0,

    coolDown: {},
};

function getLocation() {
    return {
        href: location.href,
        pathname: location.pathname,
        host: location.host,
        hostname: location.hostname,
        search: location.search,
    }
}

function fadeFragment(fragmentId) {
    const fragChildren = document.querySelectorAll(`.mg_fragment_container[data-mg-fragment-id="${fragmentId}"] > *`);
    for (const child of fragChildren) {
        child.style.setProperty("--opacity", 0.5);
        child.style.setProperty("--transition-duration", "0.8s");
    }
}

function requestUpdate(events) {
    if (events.length) {
        const fragmentId = events[0].fragment_id;
        fadeFragment(fragmentId);
    }

    wsSendObj({
        type: "request_rerun",
        location: getLocation(),
        request_id: g.nextRequestId++,
        events,
    });

    g.waitingRerun += 1;
}

function ackInvalidState() {
    wsSendObj({
        type: "ack_invalid_state",
    });
}

function btnClearFileUploader(event) {
    event.stopPropagation();
    event.preventDefault();
    const elem = event.currentTarget.parentElement;
    elem.clear();
}

function sleep(seconds) {
    // Just for testing long running operations
    return new Promise(resolve => setTimeout(resolve, seconds*1000));
}

async function uplChange(elem, oldValue, newValue) {
    const mgFiles = [];

    let maxFiles = 1;
    if (elem.hasAttribute("data-mg-multiple")) {
        maxFiles = parseInt(elem.getAttribute("dd-max-files"));
    }

    if (newValue.length > maxFiles) {
        elem.innerHTML = `
            <dd-button class="mg-clear-button mg-icon-container" onclick="btnClearFileUploader(event)">
                <mg-icon mg-icon="material/cancel"></mg-icon>
            </dd-button>
            <div class="mg-inner-label mg-error">
                <p>
                    Please select up to ${maxFiles} file(s)
                </p>
            </div>
        `;

        newValue = [];
    } else {
        for (const file of newValue) {
            if (!file.supported) {
                let errorMessage = "";
                if (file.unsupportedReason == "TooBig") {
                    errorMessage = `${file.name} size (${(file.size/MiB).toFixed(0)} MiB) exceedes the maximum file size of ${(g.uploadMaxSize/MiB).toFixed(0)} MiB`;
                } else {
                    const accept = elem.getAttribute("dd-accept");
                    errorMessage = `${file.name} type (${(file.type || 'application/octet-stream')}) is not one of these: ${accept.split(",").join(", ")}`;
                }

                elem.innerHTML = `
                    <dd-button class="mg-clear-button mg-icon-container" onclick="btnClearFileUploader(event)">
                        <mg-icon mg-icon="material/cancel"></mg-icon>
                    </dd-button>
                    <div class="mg-inner-label mg-error">
                        <p>
                            ${errorMessage}
                        </p>
                    </div>
                `;

                newValue = [];
                break;
            }
        }
    }

    elem.continueSpinner = true;
    fadeFragment(elem.getAttribute("data-mg-fragment-id"));

    for (const file of newValue) {
        if (!file.supported) continue;

        const endpoint = `/.Magic/uploaded-files/${g.sessionId}?file_name=${file.name}&type=${file.type}`;
        const response = await fetch(endpoint, {
            method: 'POST',
            headers: {
                'Content-Type': file.type || 'application/octet-stream',
                'Content-Length': file.size,
            },
            body: file.arrayBuffer
        });

        file.arrayBuffer = null; // Free bytes now that the file is stored in the backend

        if (response.ok) {
            const payload = await response.json();
            mgFiles.push({
                id: payload.file_id,
                extension: payload.extension,
                name: file.name,
                last_modified: file.lastModified,
                size: file.size,
                type: file.type,
            });
        } else {
            // Something bad happened while posting a file. We should
            // cancel the whole operation and notify the user.
            elem.clear();
            console.error(`Failed to upload file ${file.name}`);
            break;
        }

        if (!elem.hasAttribute("data-mg-multiple")) {
            break;
        }
    }

    if (mgFiles.length) {
        let fileNamesCSV = mgFiles[0].name;

        for (let i = 1; i < mgFiles.length; ++i) {
            if (i >= 4-1) {
                const remaining = mgFiles.length - i;
                fileNamesCSV += ` and ${remaining} more`;
                break;
            }
            fileNamesCSV += ", " + mgFiles[i].name;
        }

        elem.innerHTML = `
            <dd-button class="mg-clear-button mg-icon-container" onclick="btnClearFileUploader(event)">
                <mg-icon mg-icon="material/cancel"></mg-icon>
            </dd-button>
            <div class="mg-inner-label">
                <p>
                    Selected files (${mgFiles.length}): <br/>
                    ${fileNamesCSV}
                </p>
            </div>
        `;
    }

    elem.removeAttribute("disabled");

    requestUpdate([{
        type: "change",
        widget_id: elem.getAttribute("data-mg-id"),
        fragment_id: elem.getAttribute("data-mg-fragment-id"),
        new_value: mgFiles,
    }]);
}

function btnClick(event) {
    const elem = event.currentTarget;
    const widgetId = elem.getAttribute("data-mg-id");
    const fragmentId = elem.getAttribute("data-mg-fragment-id");

    if (elem.hasAttribute("data-mg-download")) {
        const a = document.createElement("a");
        a.href = `/.Magic/served-files/.download/${g.sessionId}?request_id=${g.nextRequestId++}&fragment_id=${fragmentId}&widget_id=${widgetId}`;
        a.download = elem.getAttribute("data-mg-download");
        a.click();

        fadeFragment(fragmentId);
    } else {
        requestUpdate([{
            type: "click",
            widget_id: widgetId,
            fragment_id: fragmentId,
        }]);
    }
}

function mslChange(oldValue, newValue, elem) {
    if (Array.isArray(newValue) && newValue.length == 0) {
        newValue = null;
    } else if (newValue == "") {
        newValue = null;
    }

    requestUpdate([{
        type: "change",
        widget_id: elem.getAttribute("data-mg-id"),
        fragment_id: elem.getAttribute("data-mg-fragment-id"),
        old_value: oldValue,
        new_value: newValue,
    }]);
}

function cbxAnyChange(groupName) {
    const checked = DD_Checkbox.getCheckedInGroup(groupName);
    const newValue = [];
    for (const c of checked) {
        newValue.push(c.value);
    }

    const group = DD_Checkbox.getGroup(groupName);
    const fragmentId = group.checkboxes[0].getAttribute("data-mg-fragment-id");

    requestUpdate([{
        type: "change",
        widget_id: groupName,
        fragment_id: fragmentId,
        new_value: newValue,
    }]);
}

function radChange(groupName) {
    const group = DD_Radio.getGroup(groupName);
    const fragmentId = group.checkboxes[0].getAttribute("data-mg-fragment-id");

    requestUpdate([{
        type: "change",
        widget_id: groupName,
        fragment_id: fragmentId,
        new_value: DD_Radio.getGroupValue(groupName),
    }]);
}

function isNumber(value) {
    return !isNaN(value);
}

function sendDFChanges(table) {
    if (table.mg_queued_changes.length == 0) return;

    const tableElem = table.element;

    requestUpdate([{
        type: "change",
        widget_id: tableElem.getAttribute("data-mg-id"),
        fragment_id: tableElem.getAttribute("data-mg-fragment-id"),
        changes: table.mg_queued_changes,
    }]);

    table.mg_queued_changes = [];
}

function dfChange(cell) {
    if ("mgIgnoreNextChange" in cell && cell.mgIgnoreNextChange) {
        cell.mgIgnoreNextChange = false;
        return;
    }

    const table = cell.getTable();

    const oldValue = cell.getOldValue();
    let newValue = cell.getValue();

    const rowData = cell.getRow().getData();
    const rowIndex = rowData.mg_original_index;
    const columnName = cell.getField();
    const tableElem = table.element;

    const columnConfig = table.mg_column_config[columnName];
    const columnType = columnConfig.type;
    const juliaType = columnConfig.julia_type;

    if (oldValue == newValue) return;

    let ignore_changes = false;

    if (columnType == "Number") {
        if (["", undefined, null].includes(newValue)) {
            if (columnConfig.required) {
                cell.mgIgnoreNextChange = true;
                cell.setValue(oldValue);
                ignore_changes = true;
                newValue = oldValue;
            } else {
                newValue = null;
            }
        } else if (isNumber(newValue)) {
            newValue = Number(newValue);
        } else if (columnConfig.required) {
            cell.mgIgnoreNextChange = true;
            cell.setValue(oldValue);
            ignore_changes = true;
            newValue = oldValue;
        } else {
            cell.setValue(null);
            newValue = null;
        }
    } else if (columnType == "String") {
        if ([undefined, null].includes(newValue)) {
            if (columnConfig.required) {
                cell.mgIgnoreNextChange = true;
                cell.setValue(oldValue);
                ignore_changes = true;
                newValue = oldValue;
            } else {
                newValue = null;
            }
        }
    }

    if (!ignore_changes) {
        table.mg_queued_changes.push({
            row_index: rowIndex,
            column_name: columnName,
            new_value: newValue,
        });

        requestAnimationFrame(() => sendDFChanges(table));
    }
}

function inpInput(event) {
    const newValue = event.currentTarget.value;
    const id = event.currentTarget.parentElement.parentElement.getAttribute("data-mg-id");
    const fragmentId = event.currentTarget.parentElement.parentElement.getAttribute("data-mg-fragment-id");

    requestUpdate([{
        type: "change",
        widget_id: id,
        fragment_id: fragmentId,
        new_value: newValue,
    }]);
}

function inpChange(elem, oldValue, newValue) {
    const id = elem.getAttribute("data-mg-id");
    const fragmentId = elem.getAttribute("data-mg-fragment-id");

    requestUpdate([{
        type: "change",
        widget_id: id,
        fragment_id: fragmentId,
        new_value: elem.input.value == "" ? null : newValue,
    }]);
}

function sldChange(elem, oldValue, newValue) {
    const id = elem.getAttribute("data-mg-id");
    const fragmentId = elem.getAttribute("data-mg-fragment-id");

    requestUpdate([{
        type: "change",
        widget_id: id,
        fragment_id: fragmentId,
        new_value: newValue,
    }]);
}

function clrChange(event) {
    const newValue = event.currentTarget.value;
    const id = event.currentTarget.getAttribute("data-mg-id");
    const fragmentId = event.currentTarget.getAttribute("data-mg-fragment-id");

    requestUpdate([{
        type: "change",
        widget_id: id,
        fragment_id: fragmentId,
        new_value: newValue,
    }]);
}

function codeChange(event) {
    // TODO
}

function applyCSS(elem, css) {
    for (const [key, value] of Object.entries(css)) {
        if (key.startsWith("--")) {
            elem.style.setProperty(key, value);
        } else {
            elem.style[key] = value;
        }
    }
}

function applyAttributes(elem, attributes) {
    for (const [key, value] of Object.entries(attributes)) {
        elem.setAttribute(key, value);
    }
}

function coalesce(...args) {
    for (const arg of args) {
        if (arg !== null && arg !== undefined) {
            return arg;
        }
    }
    return null;
}

function getTabulatorColumnNumber(table, columnName) {
    const columns = table.getColumns();
    for (const [index, column] of columns.entries()) {
        if (column.getField() == columnName) {
            return index;
        }
    }
    return null;
}

function getTabulatorColumn(table, columnName) {
    const columns = table.getColumns();
    const index = getTabulatorColumnNumber(table, columnName);
    if (index != null) {
        return columns[index];
    }
    return null;
}

function createAppElement(parent, props, fragmentId) {
    let newElements = [];

    if (props.type == "html") {
        const elem = document.createElement(props.tag);

        applyCSS(elem, props.css);
        applyAttributes(elem, props.attributes);

        elem.innerHTML = props.inner_html;

        newElements.push(elem);
    } else if (props.type == "container") {
        const elem = document.createElement("div");

        elem.setAttribute("data-mg-id", props.id);
        applyCSS(elem, props.css);
        applyAttributes(elem, props.attributes);

        if (props.is_fragment_container) {
            elem.classList.add("mg_fragment_container");
            fragmentId = props.fragment_id;
        }

        // Sidebar
        //---------
        if (elem.classList.contains("mg-sidebar")) {
            let state = elem.classList.contains("mg-show") ? "open" : "closed";
            const oldElem = document.querySelector(`.mg-sidebar[data-mg-id="${props.id}"]`);

            if (oldElem) {
                if (oldElem.classList.contains("mg-show")) {
                    state = "open";
                } else {
                    state = "closed";
                }
            }

            MG_SetSidebarState(elem, state);
            requestAnimationFrame(() => MG_SetSidebarState(elem, state));
        }

        newElements.push(elem);
    } else if (props.type == "button") {
        let elem = document.querySelector(`[data-mg-id="${props.id}"]`);

        if (!elem) {
            elem = document.createElement("dd-button");

            let iconHTML = "";
            if (props.icon) iconHTML = `<mg-icon mg-icon="${props.icon}"></mg-icon>`;

            elem.innerHTML = `${iconHTML} ${props.label}`;
            elem.classList.add("mg-button");

            if (props.style) {
                elem.classList.add(`mg-button-style-${props.style}`);
            }

            elem.setAttribute("data-mg-container-id", props.container_id);
            elem.setAttribute("data-mg-local-id", props.local_id);
            elem.setAttribute("data-mg-id", props.id);

            if (props.download_name) {
                elem.setAttribute("data-mg-download", props.download_name);
            }

            elem.addEventListener("click", btnClick);
        } else {
            if (props.download_name) {
                elem.setAttribute("data-mg-download", props.download_name);
            }

            elem.setAttribute("dd-reconnecting", "");
            if (DD_Components.isFocused(elem)) {
                requestAnimationFrame(()=>{
                    elem.focus();
                });
            }
        }

        newElements.push(elem);
    } else if (props.type == "text") {
        const elem = document.createElement("p");
        elem.innerText = props.text;
        newElements.push(elem);
    } else if (props.type == "text_input") {
        let elem = document.querySelector(`[data-mg-id="${props.id}"]`);

        if (!elem) {
            elem = document.createElement("dd-input");
            elem.classList.add("mg-text-input");

            elem.setAttribute("data-mg-id", props.id);

            if (props.value != null) {
                elem.setAttribute("value", props.value);
            }

            elem.setAttribute("placeholder", props.placeholder);

            elem.setAttribute("dd-onchange", "inpChange(event)");
        } else {
            elem.setAttribute("dd-reconnecting", "");

            if (props.value && elem.input.value != props.value) {
                elem.setAttribute("value", props.value);
            } else if (!props.value && elem.input.value) {
                elem.setAttribute("value", "");
            }

            if (DD_Components.isFocused(elem.input)) {
                requestAnimationFrame(()=>{
                    elem.input.focus();
                });
            }
        }

        newElements.push(elem);
    } else if (props.type == "number_input") {
        let elem = document.querySelector(`[data-mg-id="${props.id}"]`);

        if (!elem) {
            elem = document.createElement("dd-input");
            elem.setAttribute("type", "number");
            elem.setAttribute("dd-decimal-separator", props.decimal_separator);
            elem.setAttribute("dd-thousands-separator", props.thousands_separator);
            elem.setAttribute("dd-precision", props.precision);
            elem.setAttribute("dd-step", props.step);
            if (props.min != null) elem.setAttribute("dd-min", props.min);
            if (props.max != null) elem.setAttribute("dd-max", props.max);
            elem.classList.add("mg-text-input");

            elem.setAttribute("data-mg-id", props.id);

            if (props.value != null) {
                elem.setAttribute("value", props.value);
            }

            elem.setAttribute("placeholder", props.placeholder);

            elem.setAttribute("dd-onchange", "inpChange(event)");
        } else {
            elem.setAttribute("dd-reconnecting", "");

            if (props.value && elem.value != props.value) {
                elem.setAttribute("value", props.value);
            } else if (!props.value && elem.input.value) {
                elem.setAttribute("value", "");
            }

            if (DD_Components.isFocused(elem.input)) {
                requestAnimationFrame(()=>{
                    elem.input.focus();
                });
            }
        }

        newElements.push(elem);

    } else if (props.type == "slider") {
        let elem = document.querySelector(`[data-mg-id="${props.id}"]`);

        if (!elem) {
            elem = document.createElement("dd-slider");
            elem.setAttribute("dd-decimal-separator", props.decimal_separator);
            elem.setAttribute("dd-thousands-separator", props.thousands_separator);
            elem.setAttribute("dd-precision", props.precision);

            elem.setAttribute("dd-min", props.min);
            elem.setAttribute("dd-max", props.max);
            elem.setAttribute("dd-step", props.step);

            elem.setAttribute("data-mg-id", props.id);

            elem.classList.add("mg-slider");

            if (props.value != null) {
                elem.setAttribute("value", props.value);
            }

            elem.setAttribute("placeholder", props.placeholder);

            elem.setAttribute("dd-onchange", "sldChange(event)");
        } else {
            elem.setAttribute("dd-reconnecting", "");

            if (props.value && elem.value != props.value) {
                elem.value = props.value;
            }
        }

        newElements.push(elem);
    } else if (props.type == "selectbox") {
        let inpElem = document.querySelector(`dd-input[data-mg-id="${props.id}"]`);
        let slcElem = document.querySelector(`dd-select[data-mg-id="${props.id}"]`);

        if (!inpElem) {
            inpElem = document.createElement("dd-input");
            inpElem.classList.add("mg-selectbox");

            for (const [key, value] of Object.entries(props.css)) {
                inpElem.style[key] = value;
            }

            slcElem = document.createElement("dd-select");
            slcElem.classList.add("mg-selectbox");

            if (props["multiple"]) {
                slcElem.setAttribute("dd-multiple", "");
            }

            slcElem.setAttribute("dd-placeholder", props["placeholder"]);
            slcElem.setAttribute("dd-onchange", "mslChange()");

            slcElem.setAttribute("dd-width", "anchor");
            slcElem.setAttribute("data-mg-container-id", props.container_id);
            slcElem.setAttribute("data-mg-local-id", props.local_id);
            slcElem.setAttribute("data-mg-id", props.id);

            for (const op of props.options) {
                const optElem = document.createElement("dd-option");
                optElem.setAttribute("value", op);
                optElem.setAttribute("dd-text", op);
                slcElem.appendChild(optElem);
            }
        }

        if (props.value != null) {
            requestAnimationFrame(() => slcElem.setValue(props.value, {silent: true}));
        }

        newElements.push(inpElem);
        newElements.push(slcElem);
    } else if (props.type == "color_picker") {
        let elem = document.querySelector(`[data-mg-id="${props.id}"]`);

        if (!elem) {
            elem = document.createElement("input");
            elem.setAttribute("type", "color");
            elem.setAttribute("onchange", "clrChange(event)");
            elem.setAttribute("data-mg-container-id", props.container_id);
            elem.setAttribute("data-mg-local-id", props.local_id);
            elem.setAttribute("data-mg-id", props.id);

            let value = props.value ? props.value : "#999999";
            elem.setAttribute("value", value);

            applyCSS(elem, props.css)
        } else {
            elem.value = props.value;
        }

        newElements.push(elem);
    } else if (props.type == "checkboxes") {
        const cbxGroup = DD_Checkbox.getGroup(props.id);

        if (!cbxGroup) {
            for (const op of props.options) {
                const elem = document.createElement("dd-checkbox");
                elem.setAttribute("dd-group", props.id);
                elem.setAttribute("dd-onanychange", "cbxAnyChange()");

                elem.innerText = op;
                elem.value = op;

                if (!props.multiple) {
                    if (props.value) {
                        elem.setAttribute("checked", "");
                    }
                } else {
                    if (props.value.includes(elem.value)) {
                        elem.setAttribute("checked", "");
                    } else {
                        elem.removeAttribute("checked");
                    }
                }

                newElements.push(elem);
            }
        } else {
            newElements = cbxGroup.checkboxes;
            for (const elem of newElements) {
                elem.setAttribute("dd-reconnecting", "");
                elem.setAttribute("dd-silent", "");

                if (props.multiple) {
                    if (props.value.includes(elem.value)) {
                        elem.setAttribute("checked", "");
                    } else {
                        elem.removeAttribute("checked", "");
                    }
                } else {
                    if (props.value) {
                        elem.setAttribute("checked", "");
                    } else {
                        elem.removeAttribute("checked", "");
                    }
                }
            }

            requestAnimationFrame(() => {
                for (const elem of newElements) {
                    elem.removeAttribute("dd-silent");
                }
            });
        }

    } else if (props.type == "radio") {
        const group = DD_Radio.getGroup(props.id);

        if (!group) {
            for (const op of props.options) {
                const elem = document.createElement("dd-radio");
                elem.setAttribute("dd-group", props.id);

                elem.innerText = op;
                elem.value = op;

                if (op == props.options[0]) {
                    elem.setAttribute("dd-onanychange", "radChange()");
                }

                newElements.push(elem);
            }
        } else {
            const elems = document.querySelectorAll(`dd-radio[dd-group="${props.id}"]`);
            newElements = Array.from(elems);
            for (const elem of elems) {
                elem.setAttribute("dd-reconnecting", "");
            }
        }

        requestAnimationFrame(() => {
            DD_Radio.selectInGroup(props.id, props.value, {silent: true});
        })
    } else if (props.type == "image") {
        let elem = document.querySelector(`[data-mg-id="${props.id}"]`);

        if (!elem) {
            // elem = document.createElement("img");
            elem = props.img;

            elem.classList.add("mg-image");
            //elem.setAttribute("src", props.uri);
            if (props.width) elem.setAttribute("width", props.width);
            if (props.height) elem.setAttribute("height", props.height);
            elem.setAttribute("data-mg-id", props.id);
            applyCSS(elem, props.css);
        }

        newElements.push(elem);
    } else if (props.type == "dataframe") {
        let elem = document.querySelector(`[data-mg-id="${props.id}"]`);

        if (!elem) {
            elem = document.createElement("div");

            elem.setAttribute("data-mg-container-id", props.container_id);
            elem.setAttribute("data-mg-local-id", props.local_id);
            elem.setAttribute("data-mg-id", props.id);

            elem.style["height"] = props.height;
            elem.classList.add("mg-dataframe");

            const lining = document.createElement("div");
            lining.classList.add("mg-dataframe-lining");
            lining.setAttribute("data-mg-container-id", props.container_id);
            lining.setAttribute("data-mg-local-id", props.local_id);
            lining.setAttribute("data-mg-id", props.id);
            lining.setAttribute("data-mg-fragment-id", fragmentId);
            elem.appendChild(lining);

            for (const [i, row] of props.initial_value.entries()) {
                row.mg_original_index = i+1;
            }

            let columns = [];

            if (("initial_value" in props) && props.initial_value.length) {
                for (const columnName of Object.keys(props.initial_value[0])) {
                    if (columnName == "mg_original_index") continue;

                    let columnOptions = {
                        field: columnName,
                        title: columnName,
                        editor: null,
                    }

                    if (columnName in props.column_config) {
                        const config = props.column_config[columnName];
                        columnOptions = {
                            field: columnName,
                            title: columnName,
                            editor: config.editable ? (config.type == "Number" ? "number" : "input") : null,
                            cellEdited: config.editable ? dfChange : null,
                        }
                    }

                    columns.push(columnOptions);
                }
            }

            const table = new Tabulator(lining, {
                data: props.initial_value,
                columns,
                layout: "fitFill",
                selectableRange: true,
                selectableRangeAutoFocus: false,

                // NOTE: This activates Tabular.js handler for Delete/Backspace keydown
                // event, but it turns out that it is not good because it deletes
                // read-only cells too, and it also deletes the entire cell content
                // when the user is editing a specific cell, which is really bad UX.
                // selectableRangeClearCells: true,

                clipboard: true,
                clipboardCopyRowRange: "range",
                clipboardCopyConfig:{
                    rowHeaders: false,
                    columnHeaders: false,
                },
                clipboardPasteParser:"range",

                // NOTE: Unfortunately, we need to implement our own clipboard
                // paste action to prevent read-only cells from being edited.
                // TODO: Handle paste of a single value into multiple cells.
                clipboardPasteAction: function(clipboardData) {
                    // Get top-left cell of the active range
                    const range = table.getRanges()?.[0];
                    if(!range) return;

                    const startCell = range.getCells()[0][0];
                    const startRow = startCell.getRow().getPosition();
                    const rows = table.getRows();

                    clipboardData.forEach((pasteRow, rowOffset) => {
                        const row = rows[startRow + rowOffset - 1];
                        if(!row) return;

                        for (const [columnName, value] of Object.entries(pasteRow)) {
                            const column = getTabulatorColumn(table, columnName);
                            if (column.getDefinition().editor) {
                                const cell = row.getCell(column.getField());
                                if(!cell) return;
                                cell.setValue(value);
                            }

                        };
                    });
                },

                height: props.height,
                columnDefaults:{
                    headerSort: false,
                    editor: null,
                    resizable: "header",
                },
                editTriggerEvent:"dblclick"
            });

            table.mg_column_config = props.column_config;
            table.mg_queued_changes = [];

            // Handle Delete/Backspace
            //---------------------------------------
            lining.addEventListener("keydown", function(e) {
                if (document.activeElement.tagName == "INPUT") {
                    return;
                }

                if (e.key === "Delete" || e.key === "Backspace") {
                    let ranges = table.getRanges();

                    ranges.forEach(range => {
                        range.getCells().forEach(cells => {
                            cells.forEach(cell => {
                                if (cell.getColumn().getDefinition().editor) {
                                    cell.setValue(null);
                                }
                            });
                        });
                    });

                    e.preventDefault();
                }
            });

            setTimeout(()=> document.activeElement.blur(), 0);
        } else {
            const scrollY = elem.querySelector(".tabulator-tableholder").scrollTop;

            let refocus = null;
            if (elem.contains(document.activeElement)) {
                refocus = document.activeElement;
            }

            requestAnimationFrame(() => {
                elem.querySelector(".tabulator-tableholder").scrollTop = scrollY;
                if (refocus) refocus.focus();
            });
        }

        newElements.push(elem);
    } else if (props.type == "file_uploader") {
        let elem = document.querySelector(`[data-mg-id="${props.id}"]`);

        if (!elem) {
            elem = document.createElement("dd-file-uploader");

            elem.setAttribute("data-mg-container-id", props.container_id);
            elem.setAttribute("data-mg-local-id", props.local_id);
            elem.setAttribute("data-mg-id", props.id);
            elem.setAttribute("dd-max-size", props.max_file_size);
            if (props.multiple) {
                elem.setAttribute("data-mg-multiple", "");
                elem.setAttribute("dd-max-files", props.max_files);
            }
            elem.setAttribute("dd-onchange", "uplChange()");
            elem.classList.add("mg-file-uploader");
            if (props.types.length) {
                elem.setAttribute("dd-accept", props.types.join(","));
            }

            applyCSS(elem, props.css);

            elem.innerHTML = FILE_UPLOADER_DEFAULT_INNER_HTML;
            elem.defaultInnerHTML = FILE_UPLOADER_DEFAULT_INNER_HTML;
        } else {
            elem.setAttribute("dd-reconnecting", "");
            if (DD_Components.isFocused(elem)) {
                requestAnimationFrame(()=>{
                    elem.focus();
                });
            }
        }

        newElements.push(elem);
    } else if (props.type == "code") {
        const elem = document.createElement("div");
        applyCSS(elem, props.css);

        const textarea = document.createElement("textarea");
        elem.appendChild(textarea);

        requestAnimationFrame(() => {
            const cm = CodeMirror.fromTextArea(textarea, {
                mode: "julia",
                viewportMargin: Infinity,
                lineNumbers: props.show_line_numbers,
                readOnly: true,
                indentWithTabs: false,
                indentUnit: 4,
                extraKeys: {
                    Tab: function(cm) {
                        const spaces = Array(cm.getOption("indentUnit") + 1).join(" ");
                        cm.replaceSelection(spaces, "end");
                    }
                }
            });

            cm.on("change", codeChange);
            cm.setValue(props.initial_value);
        });

        newElements.push(elem);
    } else {
        console.error(`Unknown element type '${props.type}'`);
    }

    if (newElements.length) {
        for (const elem of newElements) {
            parent.appendChild(elem);
            elem.setAttribute("data-mg-fragment-id", fragmentId);
        }

        if (props.type == "container") {
            for (const child of props.children) {
                createAppElement(newElements[0], child, fragmentId);
            }
        }

        return newElements[0];
    } else {
        return null;
    }
}

function wsSendObj(obj) {
    if (g.devMode) {
        console.log("Sending this:");
        console.log(obj);
    }
    g.ws.send(JSON.stringify(obj));
}

function wsOnOpen() {
    if (g.devMode) {
        console.log("Connected to net-layer");
    }

    wsSendObj({
        type: "hello",
        location: getLocation(),
    });
}

function getImages(props) {
    if (props.type == "image") {
        return [props];
    } else if (props.type == "container") {
        let result = [];
        for (const child of props.children) {
            result = result.concat(getImages(child));
        }
        return result;
    }
    return [];
}

async function preloadImages(root) {
    const images = getImages(root);

    const tasks = images.map(image => {
        image.img = new Image();
        image.img.src = image.src;
        return image.img.decode().then(() => image.img);
    });

    return Promise.all(tasks);
}

async function displayRerunResponse(msg) {
    // Preload images
    //-------------------
    await preloadImages(msg.root);

    const fragmentId = msg.root["fragment_id"];

    const oldFragContainer = document.querySelector(`.mg_fragment_container[data-mg-fragment-id="${fragmentId}"]`);
    const computedStyle = getComputedStyle(oldFragContainer.firstElementChild);
    oldFragContainer.style.visibility = "hidden";

    const newFragWrapper = document.createDocumentFragment();

    const newFragContainer = createAppElement(newFragWrapper, msg.root, "");
    for (const child of newFragContainer.children) {
        child.style.setProperty("--opacity", computedStyle.opacity);
        child.style.setProperty("--transition-duration", "0.15s");
    }

    oldFragContainer.parentElement.insertBefore(newFragWrapper, oldFragContainer);
    oldFragContainer.remove();

    // Remove checkbox groups that ceased to exist
    //
    // TODO: I think this should actually be something done on the
    // disconnected event of the DD_Checkbox/DD_Radio component, when
    // the last checkbox of a group is removed.
    //-----------------------------------------------
    while (DD_Components.removeItemFromArrayIfCondition(DD_Checkbox.groups, (entry) => (entry.checkboxes.length == 0)));

    // Initialize opacity transition
    setTimeout(() => {
        for (const child of newFragContainer.children) {
            child.style.setProperty("--opacity", 1);
        }
    }, 10);

    g.lastValidRerunResponse = null;
}

async function wsOnMessage(event) {
    //console.log("Receiving this (raw):");
    //console.log(event.data);

    const msg = JSON.parse(event.data);
    g.devMode = "dev_mode" in msg ? msg["dev_mode"] : false;

    if (g.devMode) {
        console.log("Receiving this (parsed):");
        console.log(msg);
    }

    if (msg.type == "response_rerun") {
        if (msg.error == null) {
            // We only display the returned state if it is the response we are
            // *finally* waiting for. Otherwise, store this as the last valid
            // rerun response and wait for the next response.
            if (msg.request_id == g.nextRequestId-1) {
                displayRerunResponse(msg);
            } else {
                g.lastValidRerunResponse = msg;
            }
        } else if (msg.error.type == "InvalidState") {
            if (g.lastValidRerunResponse) {
                displayRerunResponse(g.lastValidRerunResponse);
            }
            ackInvalidState();
        }

        g.waitingRerun -= 1;
        g.reruns += 1;

        requestAnimationFrame(() => {
            if (g.reruns == 1) {
                magic.eventListener({type: "first_run_complete"});
            }

            magic.eventListener({type: "rerun_complete"});
        });
    } else if (msg.type == "please_refresh") {
        location.reload();
    } else if (msg.type == "response_hello") {
        g.sessionId = msg.session_id;
        g.devMode = msg.dev_mode;
        g.uploadMaxSize = msg.upload_max_size;
        g.uploadMaxFiles = msg.upload_max_files;
        if (g.devMode) {
            console.log(`Session: ${g.sessionId}`);
        }
        requestUpdate([]);
    }
}

function wsOnClose(event) {
    if (g.devMode) {
        console.log("Disconnected from net-layer");
    }
}

function wsOnError(err) {
    console.error(err);
}

function MG_SetSidebarState(sidebarElem, state) {
    const btn = sidebarElem.querySelector(".mg-sidebar-toggle-button");

    if (state == "open") {
        sidebarElem.classList.add("mg-show");
        if (btn) {
            btn.innerHTML = sidebarElem.dataset.mgCloseLabel;
        }
    } else {
        sidebarElem.classList.remove("mg-show");
        if (btn) {
            btn.innerHTML = sidebarElem.dataset.mgOpenLabel;
        }
    }
}

function MG_ToggleSidebar(event) {
    const btn = event.currentTarget;
    const sidebarElem = btn.parentElement.parentElement;

    if (sidebarElem.classList.contains("mg-show")) {
        MG_SetSidebarState(sidebarElem, "closed");
    } else {
        MG_SetSidebarState(sidebarElem, "open");
    }
}

async function loadIconMap(url) {
    const text = await fetch(url).then(r => r.text());

    const map = {};
    for (const line of text.split(/\r?\n/)) {
        if (!line.trim()) continue;
        const [name, code] = line.trim().split(/\s+/);
        map[name] = code;
    }
    return map;
}

//------------------------
// Error handling
//------------------------
function isMobileBrowser() {
  let check = false;
  (function(a){if(/(android|bb\d+|meego).+mobile|avantgo|bada\/|blackberry|blazer|compal|elaine|fennec|hiptop|iemobile|ip(hone|od)|iris|kindle|lge |maemo|midp|mmp|mobile.+firefox|netfront|opera m(ob|in)i|palm( os)?|phone|p(ixi|re)\/|plucker|pocket|psp|series(4|6)0|symbian|treo|up\.(browser|link)|vodafone|wap|windows ce|xda|xiino/i.test(a)||/1207|6310|6590|3gso|4thp|50[1-6]i|770s|802s|a wa|abac|ac(er|oo|s\-)|ai(ko|rn)|al(av|ca|co)|amoi|an(ex|ny|yw)|aptu|ar(ch|go)|as(te|us)|attw|au(di|\-m|r |s )|avan|be(ck|ll|nq)|bi(lb|rd)|bl(ac|az)|br(e|v)w|bumb|bw\-(n|u)|c55\/|capi|ccwa|cdm\-|cell|chtm|cldc|cmd\-|co(mp|nd)|craw|da(it|ll|ng)|dbte|dc\-s|devi|dica|dmob|do(c|p)o|ds(12|\-d)|el(49|ai)|em(l2|ul)|er(ic|k0)|esl8|ez([4-7]0|os|wa|ze)|fetc|fly(\-|_)|g1 u|g560|gene|gf\-5|g\-mo|go(\.w|od)|gr(ad|un)|haie|hcit|hd\-(m|p|t)|hei\-|hi(pt|ta)|hp( i|ip)|hs\-c|ht(c(\-| |_|a|g|p|s|t)|tp)|hu(aw|tc)|i\-(20|go|ma)|i230|iac( |\-|\/)|ibro|idea|ig01|ikom|im1k|inno|ipaq|iris|ja(t|v)a|jbro|jemu|jigs|kddi|keji|kgt( |\/)|klon|kpt |kwc\-|kyo(c|k)|le(no|xi)|lg( g|\/(k|l|u)|50|54|\-[a-w])|libw|lynx|m1\-w|m3ga|m50\/|ma(te|ui|xo)|mc(01|21|ca)|m\-cr|me(rc|ri)|mi(o8|oa|ts)|mmef|mo(01|02|bi|de|do|t(\-| |o|v)|zz)|mt(50|p1|v )|mwbp|mywa|n10[0-2]|n20[2-3]|n30(0|2)|n50(0|2|5)|n7(0(0|1)|10)|ne((c|m)\-|on|tf|wf|wg|wt)|nok(6|i)|nzph|o2im|op(ti|wv)|oran|owg1|p800|pan(a|d|t)|pdxg|pg(13|\-([1-8]|c))|phil|pire|pl(ay|uc)|pn\-2|po(ck|rt|se)|prox|psio|pt\-g|qa\-a|qc(07|12|21|32|60|\-[2-7]|i\-)|qtek|r380|r600|raks|rim9|ro(ve|zo)|s55\/|sa(ge|ma|mm|ms|ny|va)|sc(01|h\-|oo|p\-)|sdk\/|se(c(\-|0|1)|47|mc|nd|ri)|sgh\-|shar|sie(\-|m)|sk\-0|sl(45|id)|sm(al|ar|b3|it|t5)|so(ft|ny)|sp(01|h\-|v\-|v )|sy(01|mb)|t2(18|50)|t6(00|10|18)|ta(gt|lk)|tcl\-|tdg\-|tel(i|m)|tim\-|t\-mo|to(pl|sh)|ts(70|m\-|m3|m5)|tx\-9|up(\.b|g1|si)|utst|v400|v750|veri|vi(rg|te)|vk(40|5[0-3]|\-v)|vm40|voda|vulc|vx(52|53|60|61|70|80|81|83|85|98)|w3c(\-| )|webc|whit|wi(g |nc|nw)|wmlb|wonu|x700|yas\-|your|zeto|zte\-/i.test(a.substr(0,4))) check = true;})(navigator.userAgent||navigator.vendor||window.opera);
  return check;
}

// Taken from https://gist.github.com/hkulekci/3433850
function getOSName() {
    // This script sets OSName variable as follows:
    // "Windows"    for all versions of Windows
    // "MacOS"      for all versions of Macintosh OS
    // "Linux"      for all versions of Linux
    // "UNIX"       for all other UNIX flavors
    // "Unknown OS" indicates failure to detect the OS

    var OSName="Unknown OS";
    if (navigator.appVersion.indexOf("Win")!=-1) OSName="Windows";
    if (navigator.appVersion.indexOf("Mac")!=-1) OSName="MacOS";
    if (navigator.appVersion.indexOf("X11")!=-1) OSName="UNIX";
    if (navigator.appVersion.indexOf("Linux")!=-1) OSName="Linux";

    return OSName;
}

function getBrowser() {
    let nVer = navigator.appVersion;
    let nAgt = navigator.userAgent;
    let browserName  = navigator.appName;
    let fullVersion  = ''+parseFloat(navigator.appVersion);
    let majorVersion = parseInt(navigator.appVersion,10);
    let nameOffset,verOffset,ix;

    // In Opera, the true version is after "Opera" or after "Version"
    if ((verOffset=nAgt.indexOf("Opera"))!=-1) {
     browserName = "Opera";
     fullVersion = nAgt.substring(verOffset+6);
     if ((verOffset=nAgt.indexOf("Version"))!=-1)
       fullVersion = nAgt.substring(verOffset+8);
    }
    // In MSIE, the true version is after "MSIE" in userAgent
    else if ((verOffset=nAgt.indexOf("MSIE"))!=-1) {
     browserName = "Microsoft Internet Explorer";
     fullVersion = nAgt.substring(verOffset+5);
    }
    // In Chrome, the true version is after "Chrome"
    else if ((verOffset=nAgt.indexOf("Chrome"))!=-1) {
     browserName = "Chrome";
     fullVersion = nAgt.substring(verOffset+7);
    }
    // In Safari, the true version is after "Safari" or after "Version"
    else if ((verOffset=nAgt.indexOf("Safari"))!=-1) {
     browserName = "Safari";
     fullVersion = nAgt.substring(verOffset+7);
     if ((verOffset=nAgt.indexOf("Version"))!=-1)
       fullVersion = nAgt.substring(verOffset+8);
    }
    // In Firefox, the true version is after "Firefox"
    else if ((verOffset=nAgt.indexOf("Firefox"))!=-1) {
     browserName = "Firefox";
     fullVersion = nAgt.substring(verOffset+8);
    }
    // In most other browsers, "name/version" is at the end of userAgent
    else if ( (nameOffset=nAgt.lastIndexOf(' ')+1) <
              (verOffset=nAgt.lastIndexOf('/')) )
    {
     browserName = nAgt.substring(nameOffset,verOffset);
     fullVersion = nAgt.substring(verOffset+1);
     if (browserName.toLowerCase()==browserName.toUpperCase()) {
      browserName = navigator.appName;
     }
    }

    // trim the fullVersion string at semicolon/space if present
    if ((ix=fullVersion.indexOf(";"))!=-1)
       fullVersion=fullVersion.substring(0,ix);
    if ((ix=fullVersion.indexOf(" "))!=-1)
       fullVersion=fullVersion.substring(0,ix);

    majorVersion = parseInt(''+fullVersion,10);
    if (isNaN(majorVersion)) {
     fullVersion  = ''+parseFloat(navigator.appVersion);
     majorVersion = parseInt(navigator.appVersion,10);
    }

    let result = browserName + " " + fullVersion;

    return result;
}

function canSend(msgType) {
    let coolDown = g.coolDown[msgType];
    if (coolDown) {
        if (coolDown.cooling) {
            if (coolDown.counter + 1 <= coolDown.maxSends) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    } else {
        return true;
    }
}

function msgSent(msgType) {
    let coolDown = g.coolDown[msgType];
    if (coolDown) {
        if (coolDown.cooling) {
            ++coolDown.counter;
        } else {
            setTimeout(function() {
                coolDown.cooling = false;
                coolDown.counter = 0;
            }, coolDown.interval*1000);
            coolDown.cooling = true;
            coolDown.counter = 1;
        }
    }
}

function sendClientSideError(error) {
    if (!canSend("ClientSideError")) return;

    g.ws.send(JSON.stringify(error));

    msgSent("ClientSideError");
}

function errorHandler(event) {
    let filePath = event.filename.split("/");
    let fileName = filePath[filePath.length-1];

    let location = fileName + "(" + event.lineno + ")";
    let message = event.message;
    let stack = [];
    if (event.error) {
        stack = event.error.stack.split("\n");
    }

    let ignoredMessages = ["ResizeObserver loop limit exceeded"];

    if (!ignoredMessages.includes(message)) {
        let payload = {
            type: "error",
            location,
            message,
            stack,
            browser: getBrowser(),
            os: getOSName()
        };

        sendClientSideError(payload);
    }
}

(async function main(){
    g.materialIcons = await loadIconMap("/Magic.jl/fonts/MaterialIconsOutlined-Regular.codepoints");

    let wsEndpoint = `wss://${location.host}`;
    if (location.protocol == "http:") {
        wsEndpoint = `ws://${location.host}`;
    }

    g.ws = new WebSocket(wsEndpoint, ["ws"]);
    g.ws.addEventListener("open", wsOnOpen);
    g.ws.addEventListener("message", wsOnMessage);
    g.ws.addEventListener("close", wsOnClose);
    g.ws.addEventListener("error", wsOnError);

    window.customElements.define("mg-icon", MG_Icon);

    // Error handling
    //----------------
    g.coolDown["ClientSideError"] = {
        cooling: false,
        counter: 0,
        interval: 1, // interval between cooldown timer reset
        maxSends: 10 // max messages within interval
    };

    window.addEventListener("error", errorHandler);
})();
