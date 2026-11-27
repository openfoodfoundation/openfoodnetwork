import moment from "moment";
window.moment = moment;

import "moment/locale/ar";
import "moment/locale/ca";
import "moment/locale/de";
import "moment/locale/en-gb";
import "moment/locale/es";
import "moment/locale/fil";
import "moment/locale/fr";
import "moment/locale/it";
import "moment/locale/nb";
import "moment/locale/nl-be";
import "moment/locale/pt-br";
import "moment/locale/pt";
import "moment/locale/ru";
import "moment/locale/sv";
import "moment/locale/tr";
import "moment/locale/pl";

// The page language is set by the server, e.g. <html lang="en-AU">.
// Setting it here rather than in an inline script means nothing
// references `moment` if this bundle failed to load.
moment.locale([document.documentElement.lang, "en"].filter(Boolean));
