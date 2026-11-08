### v0.x.x (xxxx-xx-xx)

- New: `onchange` and `args` arguments on `text_input`, `number_input` and `slider` functions.
- New: `args` argument on `color_picker` function.
- Bug-fix: progress bar width not following the size of its container when updated.
- Bug-fix: only the last fragment updating when a job is bound to several fragments; the others stayed faded with stale content.
- Bug-fix: scroll position jumping when a fragment is rerun, both in containers around the fragment and inside it.
- Bug-fix: page going blank on rerun when an expander takes the place of a different element.
- Internal: gets rid of Parameters dependency.
