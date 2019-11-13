# Permanent Evaluation 1 : API consuming service

## Rules

Your code will need to be submitted through GitHub Classroom.

The deadline for committing your code is `Sunday 8 December at 23:59`. Starting from Monday 9 December 00:00, a script will clone your repository with your solution.

__File creation/last edit time is of no relevance at all for this deadline! Your code should be online at this moment in time.__

If for some mysterious reason GitHub should be offline, you are allowed to send it by mail. GitHub uptime will also be monitored.

_This might be obvious, but not having internet access is by no means a reason to not submit your code before the deadline._

There can be small changes to this assignment (function names, small adjustments, etc...) up until `17 November`.

## Assignment

You will refactor your code and implement new features written below.

Requirements:

* The startup file should no longer exist.
* Use the application configuration to configure:
  * This configuration should be stored under root_folder/config/config.exs
  * [Relevant documentation](https://hexdocs.pm/elixir/Config.html)
  * Your timeframe (previously `@from` and `@until` module attributes in the startup file.)
  * The api request/s limit.
* The configuration file must contain the following settings:
  * `@until` must be set to `DateTime.utc_now() |> DateTime.to_unix()`
  * `@from` must be set to `(DateTime.utc_now() |> DateTime.to_unix()) - 60 * 60 * 24 * 7`
  * `@rate` must be set to `5`
* For the part regarding your process manager and worker processes:
  * Use an appropriate supervisor construction for your process manager and worker processes.
  * Your process manager is allowed to crash as long as it does not impact the rest of your application.
  * The process manager name registration stays the same.
  * Use a supervisor that supports dynamic workers out of the box and name-register this as `AssignmentTwo.CoindataRetrieverSupervisor`.
  * Worker processes (`AssignmentOne.CoindataRetriever` processes) are started in the process manager.
  * By no means should the "starting processes" part impact the rest of your application. This means that the supervisor supervising this process manager should not "hang".
  * The process manager should not be able to have an invalid state.
  * Put simply, the above 3 points all indicate that you should start your processes in the `handle_continue` callback. This is very important.
  * The responsibility of "rebooting" your crashed processes is no longer with the process manager, but with the supervisor supervising these processes.
  * Your workers no longer keep your history. More about this in the next section.
* Some great students mentioned that when the process crashes, the history shouldn't be lost with it. They were completely right! For this reason, we're refactoring the following:
  * Similar to our worker setup with supervisors, we're going to do the same for our history keepers.
  * Make a `AssignmentTwo.HistoryKeeperManager`. Similar to our process manager (which is kind of an ambigious name now, but let's forget about that), it'll start N `AssignmentTwo.HistoryKeeperWorker` workers under a supervisor that supports dynamic workers out of the box and name-register this as `AssignmentTwo.HistoryKeeperSupervisor`.
  * This `HistoryKeeperManager` will ask your process manager what coin pairs are supported.
  * [VERIFY] Your `HistoryKeeperManager` should by no means hold an invalid state when starting your application. (Hint, `handle_continue`!)
  * Every`HistoryKeeperWorker` will keep the history of a specific coin pair.
  * The `CoindataRetriever` worker will ask the responsible `HistoryKeeperWorker` what it should still clone.
  * [EXTRA] You can update the timeframe of a specific coin.
* We're going to make our Logger a little bit more fancy:
  * When printing a message, we can give a "level" towards this message. This level indicates whether it is a debug message, information message, warning, etc... Use the levels mentioned [here](https://hexdocs.pm/logger/Logger.html).

## Module names, constraints, method names & tests

* TODO method names -> this should just be refactoring of your method names.
* TODO tests -> I'll provide **_indicative_** tests, which can be adjusted based on your implementation.
