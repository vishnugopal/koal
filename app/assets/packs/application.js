import { Application } from "stimulus";
import { definitionsFromContext } from "stimulus/webpack-helpers";

import "../images/index.js.erb";
import "../stylesheets/index.js.erb";
import "../javascripts/index.js";

const application = Application.start();
const context = require.context("javascripts/controllers", true, /.js$/);
application.load(definitionsFromContext(context));
