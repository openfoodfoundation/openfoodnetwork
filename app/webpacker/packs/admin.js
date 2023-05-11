import "controllers";
import "channels";
import "@hotwired/turbo";
import "../js/mrujs";

import debounced from "debounced";
debounced.initialize({ input: { wait: 300 } });
