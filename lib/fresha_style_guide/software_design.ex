defmodule FreshaStyleGuide.SoftwareDesign do
  @moduledoc """
  Higher level application design and engineering guidelines.
  """

  @doc """
  An `else` block should be provided for `with` when it forwards cases from external files.

  ## Reasoning

  The `with` clause allows to omit `else` entirely if its only purpose is to amend the specific
  series of matches filled between `with` and `do`. In such cases, all non-matching outputs are
  forwarded (or "bubbled up") by `with`. This is a cool feature that allows to reduce the amount of
  redundant negative matches when there's no need to amend them.

  It may however become a readability and maintenance problem when `with` calls to complex, external
  code from separate files, which makes it hard to reason about the complete set of possible
  outcomes of the whole `with` block. Therefore, it's encouraged to provide an `else` which lists
  a complete set of possible negative scenarios, even if they are not mapped to a different output.

  ## Examples

  Preferred:

      defmodule RegistrationService do
        def call(attrs) do
          with {:ok, user} <- CreateUserFromAttributesService.call(attrs),
               :ok <- SendUserWelcomeEmailService.call(user)
          do
            {:ok, user}
          else
            {:error, changeset = %Ecto.Changeset{}} -> {:error, changeset}
            {:error, :not_available} -> {:error, :not_available}
          end
        end
      end

  Unclear cross-module flow:

      defmodule RegistrationService do
        def call(attrs) do
          with {:ok, user} <- CreateUserFromAttributesService.call(attrs),
               :ok <- SendUserWelcomeEmailService.call(user)
          do
            {:ok, user}
          end
        end
      end

  """
  def with_else_usage, do: nil

  @doc """
  Redundant `else` block should not be provided for the `with` directive.

  ## Reasoning

  In cases when all the code called in `with` resides in the same file (or in a standard library)
  and when none of `else` clauses would override the negative path's output, it's more semantic and
  descriptive to simply drop the `else` entirely. It's worth noting that `else` blocks in `with`
  bring an additional maintenance cost so it should be excused by either of conditions mentioned
  above.

  ## Examples

  Preferred:

      defmodule RegistrationService do
        def call(attrs) do
          with {:ok, user} <- insert_user(attrs),
               :ok <- send_welcome_email(user)
          do
            {:ok, user}
          end
        end

        defp insert_user(attrs), do: # ...

        defp send_welcome_email(user), do: # ...
      end

  Redundant and hard to maintain `else`:

      defmodule RegistrationService do
        def call(attrs) do
          with {:ok, user} <- insert_user(attrs),
               :ok <- send_welcome_email(user)
          do
            {:ok, user}
          else
            {:error, :insertion_error_a} -> {:error, :insertion_error_a}
            {:error, :insertion_error_b} -> {:error, :insertion_error_b}
            {:error, :insertion_error_c} -> {:error, :insertion_error_c}
            {:error, :mailing_service_error_a} -> {:error, :mailing_service_error_a}
            {:error, :mailing_service_error_b} -> {:error, :mailing_service_error_b}
            {:error, :mailing_service_error_c} -> {:error, :mailing_service_error_c}
          end
        end

        defp insert_user(attrs), do: # ...

        defp send_welcome_email(user), do: # ...
      end

  """
  def with_else_redundancy, do: nil

  @doc """
  Matches in a `with-else` block should be placed in occurrence order.

  ## Reasoning

  Doing this will make it much easier to reason about the whole flow of the `with` block, which
  tends to be quite complex and a core of flow control.

  ## Examples

  Preferred:

      defmodule RegistrationService do
        def call(attrs) do
          with {:ok, user} <- CreateUserFromAttributesService.call(attrs),
               :ok <- SendUserWelcomeEmailService.call(user)
          do
            {:ok, user}
          else
            {:error, changeset = %Ecto.Changeset{}} -> {:error, changeset}
            {:error, :not_available} -> {:error, :not_available}
          end
        end
      end

  Unclear flow:

      defmodule RegistrationService do
        def call(attrs) do
          with {:ok, user} <- CreateUserFromAttributesService.call(attrs),
               :ok <- SendUserWelcomeEmailService.call(user)
          do
            {:ok, user}
          else
            {:error, :not_available} -> {:error, :not_available}
            {:error, changeset = %Ecto.Changeset{}} -> {:error, changeset}
          end
        end
      end

  """
  def with_else_order, do: nil

  @doc """
  Errors from external contexts should be mapped to have a meaning in the current context.

  ## Reasoning

  Elixir allows to match and forward everything in `case` and `with-else` match clauses (which are
  often used to control the high level application flow) or to simply omit `else` for `with`. This
  often results in bubbling up errors, such as those in `{:error, reason}` tuples, to the next
  context in which those errors are ambiquous or not fitting the context into which they traverse.
  For instance, `{:error, :forbidden}` returned from a HTTP client is ambiguous and not fitting the
  context of a service or controller that calls it. The following questions are unanswered:

  - what exactly is forbidden?
  - why would I care if it's forbidden and not, for instance, temporarily unavailable?
  - what actually went wrong?
  - how does it map to actual input args?

  A reverse case is also possible when errors in lower contexts are intentionally named to match
  upper context expectations, breaking the separation of concerns. For instance, a service may
  return `{:error, :not_found}` or `{:error, :forbidden}` in order to implicitly fall into fallback
  controller's expectations, even though a more descriptive error naming could've been invented.

  Therefore, care should be put into naming errors in a way that matters in the contexts where
  they're born and into leveraging `case` and `with-else` constructs to re-map ambiguous or not
  fitting errors into a meaningful and fitting ones when they travel across context bounds.

  ## Examples

  Preferred:

      defmodule RegistrationService do
        def call(attrs) do
          with {:ok, user} <- CreateUserFromAttributesService.call(attrs),
               :ok <- SendUserWelcomeEmailService.call(user)
          do
            {:ok, user}
          else
            {:error, changeset = %Ecto.Changeset{}} -> {:error, :invalid_attributes, changeset}
            {:error, :not_available} -> {:error, :mailing_service_not_available}
          end
        end
      end

  Ambiguous and "out of context" errors:

      defmodule RegistrationService do
        def call(attrs) do
          with {:ok, user} <- CreateUserFromAttributesService.call(attrs),
               :ok <- SendUserWelcomeEmailService.call(user)
          do
            {:ok, user}
          else
            {:error, changeset = %Ecto.Changeset{}} -> {:error, changeset}
            {:error, :not_available} -> {:error, :not_available}
          end
        end
      end

  """
  def error_mapping, do: nil

  @doc """
  Non-false moduledoc should be filled only for global, context-external app modules.

  ## Reasoning

  Filling moduledoc results in adding the module to module list in the documentation. Therefore, it
  makes little sense to use it only to leave a comment about internal mechanics of specific module
  or its meaning in the context of a closed application domain. For such cases, regular comments
  should be used. This will yield a clean documentation with eagle-eye overview of the system and
  its parts that can be directly used from global or external perspective.

  ## Example

  Preferred:

      defmodule MyProject.Accounts do
        @moduledoc \"""
        Account management system.
        \"""

        @doc \"""
        Registers an user account.
        \"""
        def register(attrs) do
          MyProject.Accounts.RegistrationService.call(attrs)
        end
      end

      defmodule MyProject.Accounts.RegistrationService do
        @moduledoc false

        # Fails on occasion due to Postgres connection issue.
        # Works best on Fridays.

        def call(attrs) do
          # ...
        end
      end

  Unnecessary external-ization and comment duplication:

      defmodule MyProject.Accounts do
        @moduledoc \"""
        Account management system.
        \"""

        @doc \"""
        Registers an user account.
        \"""
        def register(attrs) do
          MyProject.Accounts.RegistrationService.call(attrs)
        end
      end

      defmodule MyProject.Accounts.RegistrationService do
        @moduledoc \"""
        Registers an user account.

        Fails on occasion due to Postgres connection issue.
        Works best on Fridays.
        \"""

        def call(attrs) do
          # ...
        end
      end

  """
  def moduledoc_usage, do: nil

  @doc """
  Usage of `import` directive at module level or without the `only` option should be avoided.

  ## Reasoning

  When importing at module level, one adds a set of foreign functions to the module that may
  conflict with existing ones. This gets worse when multiple modules are imported and their names
  start to clash with each other. When project complexity increases over time and the preference for
  imports over aliases grows, the developer will sooner or later be forced to name functions in a
  custom to-be-imported module in a way that scopes them in a target module and/or avoids naming
  conflicts with other to-be-imported modules. This results in bad function naming - names start to
  be unnecessarily long or to repeat the module name in a function name.

  When importing without the `only` option, it's unclear without visiting the source of imported
  module what exact function names and arities come from the external place. This makes the code
  harder to reason about.

  ## Examples

  Preferred:

      defmodule User do
        def full_name(%{first_name: first_name, last_name: last_name}) do
          import Enum, only: [join: 2]

          join([first_name, last_name])
        end
      end

  Too wide scope:

      defmodule User do
        import Enum, only: [join: 2]

        def full_name(%{first_name: first_name, last_name: last_name}) do
          join([first_name, last_name])
        end
      end

  Unknown imports:

      defmodule User do
        def full_name(%{first_name: first_name, last_name: last_name}) do
          import Enum

          join([first_name, last_name])
        end
      end

  """
  def import_usage, do: nil

  @doc """
  Tests should only `use` support test case modules that they need.

  ## Reasoning

  If specific test only unit tests a module without using a web request, it shouldn't use `ConnCase`
  and if it doesn't create records, it shouldn't use `DataCase`. For many tests, `ExUnit.Case` will
  be enough of a support.

  This yields more semantic test headers and avoids needlessly importing and abusing of more complex
  support files.

  ## Examples

  Preferred:

      defmodule MyProject.Web.MyControllerTest do
        use MyProject.Web.ConnCase
      end

      defmodule MyProject.MyServiceTest do
        use MyProject.DataCase
      end

      defmodule NeitherControllerNorDatabaseTest do
        use ExUnit.Case
      end

  Test support file abuse:

      defmodule MyProject.MyServiceTest do
        use MyProject.Web.ConnCase
      end

      defmodule NeitherControllerNorDatabaseTest do
        use MyProject.DataCase
      end

  """
  def test_case_usage, do: nil

  @doc """
  Sequential variable names, like `user1`, should respect underscore naming (and be avoided).

  ## Reasoning

  Sequential variable names should be picked only as a last resort, since they're hard to express
  in underscore notation and are non-descriptive. For instance, in comparison function
  `compare(integer_1, integer_2)` can be replaced with `compare(integer, other_integer)`.

  Sequence number added as suffix without the underscore is a breakage of underscore naming and
  looks especially bad when the name consists of more than one word, like `user_location1`.

  ## Examples

  Preferred:

      def compare(integer, other_integer), do: # ...

  Preferred as last resort:

      def add_three_nums(integer_1, integer_2, integer_3), do: # ...

  Plain ugly:

      def concat(file_name1, file_name2), do: # ...
  """
  def sequential_variable_naming, do: nil

  @doc """
  Predicate function names shouldn't start with `is_` and should end with `?`.

  ## Reasoning

  It's an Elixir convention to name predicate functions with a `?` suffix. It leverages the fact
  that this character can appear as function name suffix to make it easier to differentiate such
  functions from others.

  It's also an Elixir convention not to name predicate functions with a `is_` prefix, since that
  prefix is reserved for guard-enabled predicate macros.

  > Note that this rule doesn't apply to service functions that return success tuples instead of
    plain boolean values.

  ## Examples

  Preferred:

      def active?(user), do: true

  Function that pretends to be a guard:

      def is_active?(user), do: true

  Function that pretends not to be a predicate:

      def active(user), do: true

  """
  def predicate_function_naming, do: nil

  @doc """
  Functions should be grouped by their relationship rather than by "public then private".

  ## Reasoning

  The existence of a `def` + `defp` directive pair allows to leave behind the old habits for
  defining all the public functions before private ones. Keeping related functions next to each
  other allows to read the code faster and to easily get the grasp of the whole module flow.

  The best rule of thumb is to place every private function directly below first other function that
  calls it.

  ## Examples

  Preferred:

      def a, do: b()

      defp a_helper, do: nil

      def b, do: nil

      defp b_helper, do: nil

  Harder to read:

      def a, do: b()

      def b, do: nil

      defp a_helper, do: nil

      defp b_helper, do: nil

  """
  def function_order, do: nil

  @doc """
  Flow control directives should be leveraged to yield compact and readable code.

  ## Reasoning

  Each of flow control directives (`if`, `cond`, `case`, `with`) has its own purpose, but sometimes
  more than one of them can be used to achieve the same goal. In such cases, the one that yields the
  most compact and readable code should be picked.

  ## Examples

  Preferred:

      with {:ok, user} <- load_user(id),
           {:ok, avatar} <- load_user_avatar(user)
      do
        {:ok, user, avatar}
      end

  Redundant `case` equivalent of the above:

      case load_user(id) do
        {:ok, user} ->
          case load_user_avatar(user) do
            {:ok, avatar} ->
                {:ok, user, avatar}
            error -> error
          end
        error -> error
      end

  """
  def flow_directive_usage, do: nil

  @doc """
  Pattern matching should be preferred over line-by-line destructuring of maps and structs.

  ## Reasoning

  Pattern matching can be used to vastly simplify destructuring of complicated structures, so it
  should be used whenever possible, instead of taking out field by field via a struct getter (`.`)
  or an access operator (`[]`).

  It's supported in function clauses, so extensive use of the feature will also encourage writing
  more pattern-matched functions, which should in turn yield a code easier to parse for Elixir
  developers. Function headers with long matches can be easily broken into multiple lines and
  indented in a clean way, so the length of a match should not be the factor for making a decision
  about using or not using it.

  Even outside of function clauses, pattern matching is a blazing fast VM-supported feature that,
  combined with guards unwrapped at compilation time, should yield the best possible code
  performance.

  It's also worth mentioning that pattern matching can be also done inside of the `assert` macro
  in `ExUnit` in order to write selective, nicely diffed assertions on maps and structs.

  Pattern matching should not be preferred over functions from `Keyword` module for destructuring
  option lists, even if they can hold only one possible option at a time.

  ## Examples

  Preferred in function clauses:

      def create_user_from_json_api_document(%{
        "data" => %{
          "id" => id,
          "attributes" => %{
            "name" => name,
            "email" => email,
            "phone" => phone
          }
        }
      }, mailing_enabled) do
        user = insert_user(id, name, email, phone)
        if mailing_enabled, do: send_welcome_email(user)
      end

  Preferred in tests:

      assert %User{
        name: "John",
        phone: "+48 600 700 800"
      } == CreateUserAction(name: "John", email: email_sequence(), phone: "+48 600 700 800")

  Cluttered:

      id = doc["data"]["id"]
      name = doc["data"]["attributes"]["name"]
      email = doc["data"]["attributes"]["email"]
      phone = doc["data"]["attributes"]["phone"]

  """
  def pattern_matching_usage, do: nil

  @doc """
  Kernel macros for working with nested structures should be preferred over manual assembly.

  This is about macros from the `*_in` family in the `Elixir.Kernel` module, like `pop_in`,
  `put_in` or `update_in`.

  ## Reasoning

  Using these macros can vastly reduce the amount of code amd ensure that the complexity of digging
  and modifying nested structures is handled in the fastest way possible, as guaranteed by relying
  on a standard library. Implementing these flows manually leads to repetitive code and an open door
  for extra bugs.

  ## Examples

  Preferred:

      opts = [
        user: [
          name: "John",
          email: "user#xample.com"
        ]
      ]

      opts_with_phone = put_in opts[:user][:phone], "+48 600 700 800"

  Unneeded complexity:

      opts = [
        user: [
          name: "John",
          email: "user#xample.com"
        ]
      ]

      user_with_phone = Keyword.put(opts[:user], :phone, "+48 600 700 800")
      opts_with_phone = Keyword.put(opts, :user, user_with_phone)

  """
  def nested_struct_macro_usage, do: nil

  @doc """
  Keyword lists and tuples should be preferred over maps and lists for passing options.

  ## Reasoning

  Keyword lists and tuples are a standard, conventional means for passing internal information
  between Elixir modules.

  Keyword lists enforce a usage of atoms for keys and allow to pass single key more than once and in
  specific order when that's desired (and provide a `merge` function for when that's not desired).
  The price for last two feats is that they are not pattern-matchable (and should never be pattern
  matched) in cases when order and duplication is not important - functions from the
  `Elixir.Keyword` module should be used in those cases. Ot the other hand, pattern matching may
  come handy when parsing options with significant order of keys.

  Tuples declare a syntax for short, efficient, predefined lists and are useful in simpler and
  convention-driven cases, in which key naming is not needed. For instance, there's an established
  convention to return `{:ok, result}`/`{:error, reason}` tuples from actions that can succeed or
  fail without throwing.

  ## Examples

  Preferred:

      defp create_user(attrs, opts \\\\ []) do
        # required option
        auth_scope = Keyword.fetch!(opts, :send_welcome_email, false)

        # options with defaults
        send_welcome_email = Keyword.get(opts, :send_welcome_email, false)
        mark_as_confirmed = Keyword.get(opts, :mark_as_confirmed, true)

        case Repo.insert(%User{}, attrs) do
          {:ok, user} ->
            final_user =
              user
              |> send_email(send_welcome_email)
              |> confirm(mark_as_confirmed)
            {:ok, final_user}

          {:error, changeset} ->
            {:error, map_changeset_errors_to_error_reason(changeset.errors)}
        end
      end

  Invalid usage of maps over keyword lists:

      defp create_user(attrs, opts = %{}) do
        # ...
      end

  Invalid usage of lists over tuples:

      defp create_user(attrs) do
        # ...

        [:ok, user]
      end

  """
  def option_format, do: nil

  @doc ~S"""
  Errors should be thrown as close to the spot of failure and unhandled unless required.

  ## Reasoning

  Throwing an exception (or using a throwing equivalent of a standard library function) allows to
  avoid spending an additional time on inventing failure paths in the code and handling them higher
  in the call stack.

  It may be tempting to go with an error return value, such as the `{:error, ...}` tuple, in order
  to let the code higher in the call stack to decide what to do in a specific situation, but that
  only makes sense when it makes sense, ie. there exists a valid case higher in the call stack that
  would want to do something other than throwing or returning a meaningless, generic error.

  Otherwise, when a hard system-wide failure ends up not being an exception, it may look like a step
  towards reusability, but it's really anti-semantic and the specific code unit (function or module)
  stops telling the whole story, ie. multiple files must be read in order to come up with a simple
  conclusion that we really end up with an exception anyway.

  This may be extra important during a debugging session, since the closer an exception happens to
  the spot of failure, the easier it is for developer to understand the real reason behind it. For
  the same reason, it's always better to use a throwing equivalent of a standard library function
  (with the `!` suffix) in places which don't handle the negative scenario anyway further down the
  pipe.

  ## Examples

  Preferred:

      def do_something_external(params) do
        required = Keyword.fetch!(params, :required)
        optional = Keyword.get(params, :optional)
        integer =
          params
          |> Keyword.fetch!(:integer)
          |> String.to_integer

        case external_api_call(required, optional, integer) do
          %{status: 200, body: body} ->
            body["result"]
          %{status: error_status, body: error_body} ->
            raise("External API error #{error_status}: #{inspect error_body}")
        end
      end

  Bad code (read the explanation below):

      def do_something_external(params) do
        required = Keyword.get(params, :required)
        optional = Keyword.get(params, :optional)
        {integer, _} =
          params
          |> Keyword.fetch!(:integer)
          |> Integer.parse

        case external_api_call(required, optional, integer) do
          %{status: 200, body: body} ->
            {:ok, body["result"]}
          _ ->
            {:error, :external_api_failed}
        end
      end

  There are following problems in the code above:

  - not throwing on forgotten `:required_option` as early as possible will yield problems further
    down the pipe that will be hard to debug since debugging session will have to track the issue
    back to the original spot that we could've thrown at since the beginning

  - not using optimal standard library means for throwing a descriptive error for failed string to
    integer conversion (`String.to_integer`) will yield a less descriptive match error (and the
    match-all on a 2nd elem of tuple from `Integer.parse` may produce bugs)

  - returning `{:error, :external_api_failed}` on failure from external API will force the caller of
    `do_something_external` to handle this case, so it makes sense only if we can actually do
    something that makes sense (other than raising, silencing the issue or making it ambiguous)

  """
  def error_handling, do: nil

  @doc ~S"""
  Functions should return `:ok`/`:error` when both success and failure paths are present.

  ## Reasoning

  First of all, we do want to adhere to the long-standing Elixir convention of returning
  `:ok`/`:error` atoms from functions. They may either be stand-alone (simple `:ok`/`:error` when
  there's nothing more to add) or wrapped in a tuple with extra contextual info, such as `{:ok,
  fetched_data}` or `{:error, reason}`. Tuples may be mixed with stand-alone atoms, eg. the same
  function may return `:ok` upon success (since there's nothing more to add upon success) while
   multiple distinct error paths may return `{:error, reason}` to make them distinct to the caller.

  That said, there's a case when usage of this pattern may make the code more confusing. It's when
  specific code simply cannot fail. If it cannot fail, then it doesn't make sense to make it tell
  its caller that something went ok. In such cases, the function should simply return the value that
  was asked for (`fetched_data` in example above) or `nil` if there's nothing to return (eg. when a
  non-failing function only creates side effects).

  This fits nicely into the way the Elixir standard library is designed (eg. `Map.get/2` never fails
  so it only returns the value but `Map.fetch/2` does fail so it returns `{:ok, value}` or
  `:error`). As such, this rule makes our code consistent with Elixir conventions and community code
  that's supposed to follow them.

  > Refer to the `Surgex.Guide.SoftwareDesign.error_handling/0` rule in order to learn when to
    actually implement the failure path.

  ## Examples

  Preferred:

      def print_debug_info(message) do
        IO.puts(message)

        nil
      end

      def remove_file(path) do
        if File.exists?(path)
          :ok = File.rm(path)
        else
          {:error, :file_not_found}
        end
      end

  Confusing `:ok` when there's no failure path (`IO.puts/1` returns `:ok`):

      def print_debug_info(message) do
        IO.puts(message)
      end

      def remove_file(path) do
        if File.exists?(path)
          :ok = File.rm(path)
        else
          raise("No such file: #{inspect path}")
        end
      end

  Lack of `:ok` when there's a failure path (`File.read!/1` returns the file content):

      def read_file(path) do
        if File.exists?(path)
          File.read!(path)
        else
          {:error, :file_not_found}
        end
      end

  """
  def return_ok_error_usage, do: nil
end
