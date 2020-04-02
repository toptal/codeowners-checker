# Custom matchers

Here's a quick overview of the matchers introduced for specs in this project.

## Integration tests

These matchers are available in integration specs (see [integration](./integration) directory):

* `warn_with(line0, line1...)` checks that warnings containing `line0` etc have been emitted,
* `report_with(line0, line1...)` checks that messages containing `line0` etc have been reported to the user,
* `have_empty_report` checks that no messages have been reported to the user,
* `ask(question)` checks that the user has been prompted for the string `question`.

