# Ash Troubleshooting Guide
**Common pitfalls, solutions, and debugging techniques**

> **Note**: *This content was extracted from project cheatsheet.md and represents community-maintained troubleshooting patterns beyond the canonical documentation.*

## Overview

This section highlights frequent mistakes, confusing behaviors, and troubleshooting tips for working with Ash. Use these solutions to quickly resolve common issues and avoid frustration.

## Common Pitfalls & Solutions

### 1. Forgetting to Add Resources to Domains

**Symptom:**
- Compile-time error: "Resource not found in domain" or codegen/migrations do not pick up your resource.

**Solution:**
- Always add new resources to the `resources do ... end` block in your domain module.
- Example:
  ```elixir
  resources do
    resource MyApp.Accounts.User
    resource MyApp.Blog.Post
  end
  ```

### 2. Not Listing Domains in Config

**Symptom:**
- Ash tasks (codegen, migrations) do not find your resources.

**Solution:**
- Add all domain modules to your app config:
  ```elixir
  config :my_app, :ash_domains, [MyApp.Accounts, MyApp.Blog]
  ```

### 3. Using Ecto.Repo Instead of AshPostgres.Repo

**Symptom:**
- Migration/codegen errors, or AshPostgres features not working.

**Solution:**
- In your repo module, use:
  ```elixir
  use AshPostgres.Repo, otp_app: :my_app
  ```
  instead of `Ecto.Repo`.

### 4. Not Running Codegen After Resource Changes

**Symptom:**
- Database schema does not match resource definitions.

**Solution:**
- Always run:
  ```bash
  mix ash.codegen
  mix ash_postgres.migrate
  ```
  after changing resource fields or relationships.

### 5. Forgetting to Mark Attributes as Public

**Symptom:**
- Fields are not settable via create/update actions.

**Solution:**
- Mark attributes as `public?: true` if they should be accepted in actions.
- Example:
  ```elixir
  attribute :email, :string, public?: true
  ```

### 6. Not Using `accept` in Custom Actions

**Symptom:**
- Custom actions do not accept any fields by default.

**Solution:**
- Use `accept [...]` in custom actions to whitelist fields.
- Example:
  ```elixir
  create :register do
    accept [:email, :password]
  end
  ```

### 7. Not Passing `domain:` or `actor:` Options

**Symptom:**
- Errors about ambiguous resource/domain, or policies not being enforced.

**Solution:**
- Always pass the `domain:` option to Ash actions.
- Pass the `actor:` option when policies or authentication are needed.
- Example:
  ```elixir
  Ash.read!(MyApp.Accounts.User, domain: MyApp.Accounts, actor: current_user)
  ```

### 8. Policy Not Enforced or Unexpected Authorization

**Symptom:**
- Actions succeed/fail unexpectedly due to missing or misconfigured policies.

**Solution:**
- Double-check your `policies do ... end` blocks.
- Use `authorize_if` and `forbid_if` as needed.
- Ensure the `Ash.Policy.Authorizer` extension is enabled.
- Use `mix ash.generate_policy_charts` to visualize and debug policies.

### 9. Not Requiring Ash.Query or Ash.Expr in Tests

**Symptom:**
- Compile errors or query macros not working in tests.

**Solution:**
- Add `require Ash.Query` and/or `require Ash.Expr` at the top of your test modules.

### 10. Manual Migrations Out of Sync

**Symptom:**
- Database schema and Ash resource definitions diverge.

**Solution:**
- Prefer using Ash codegen for all schema changes.
- If you must write a manual migration, update the resource definition to match.

## Debugging Tips

### Built-in Debugging Tools

- Use `IO.inspect`, `dbg`, and other Elixir debugging tools to inspect data and troubleshoot issues.
- Reference [debugging.mdc](../rules/debugging.mdc) for recommended Elixir debugging tools and techniques.

### Interactive Debugging with Tidewave

> **Tip:** For advanced, interactive debugging and data inspection, use [Tidewave](https://hexdocs.pm/tidewave/):
> 1. Add `{:tidewave, "~> 0.2"}` to your `mix.exs` deps and run `mix deps.get` (if not already present)
> 2. Start an IEx session: `iex -S mix`
> 3. Call `Tidewave.start()` for a live, interactive dashboard
> 4. Use `Tidewave.inspect(data)` in code or IEx to explore any value
> - Replace `IO.inspect(data)` with `Tidewave.inspect(data)` for better visualization of complex/nested data
> - Use in tests, scripts, and debugging sessions
> - See the [Tidewave Docs](https://hexdocs.pm/tidewave/) for more examples

### Ash-Specific Debugging

- **Policy debugging**: Use `mix ash.generate_policy_charts` to visualize authorization logic
- **Query debugging**: Add `verbose?: true` to read operations to see generated SQL
- **Migration debugging**: Use `--dry-run` with codegen to preview changes
- **Action debugging**: Use `Ash.Changeset.errors/1` to inspect validation errors

### Development Workflow for Debugging

1. **Start minimal**: Create the simplest possible reproduction case
2. **Use IEx**: Interactive debugging is often faster than test-driven debugging
3. **Check logs**: Look for Ash-specific error messages and warnings
4. **Verify config**: Ensure domains are listed and repos are properly configured
5. **Test incrementally**: Add complexity gradually to isolate issues

## Performance Troubleshooting

### Common Performance Issues

- **N+1 queries**: Use `Ash.Query.load/2` to eager load relationships
- **Missing indexes**: Check generated migrations for proper indexing
- **Inefficient filters**: Use database-level constraints when possible
- **Large result sets**: Implement pagination with `Ash.Query.page/2`

### Monitoring and Profiling

- Use `:observer.start()` to monitor memory and process usage
- Add telemetry events to track Ash operation performance
- Use database query analysis tools to identify slow queries

---

*This guide covers troubleshooting patterns extracted from project experience. For the most current information, consult the [official Ash documentation](https://hexdocs.pm/ash/3.5.13/).* 