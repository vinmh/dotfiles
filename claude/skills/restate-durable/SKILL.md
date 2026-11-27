---
name: restate-durable
description: >
  Writing, changing, reviewing or testing durable code on Restate (TypeScript SDK) in DIANA: jobs,
  handlers, virtual objects, delayed or scheduled work, retries. Use whenever code imports
  @restatedev/*, runs inside a Restate handler or ctx.run step, enqueues a Restate invocation, or
  touches the job runner (D-64). Covers non-determinism, durable recovery, task separation, retry
  logic and side-effect avoidance, with facts measured on the pinned versions.
---

# Durable code on Restate

A Restate handler is not an ordinary async function. It is **replayed**: Restate keeps a journal
of every context operation (steps, state, calls, sends, sleeps) and, after any failure, suspension
or retry, runs the handler again **from the top**, feeding back the recorded results instead of
redoing the work. The same model as Temporal's workflows (handler body = workflow code, `ctx.run`
step = activity), without a separate worker. Code that's correct for one run can be wrong on the
second, and the second run happens on every crash, deploy, slow step (> inactivity timeout) and
retry. Write every handler as if it will run many times, because it will.

Versions (pinned, D-64): `@restatedev/restate-sdk` **1.18.2**, `restate-server` **1.8.1**, CLI
**1.8.1**. "Measured" below means `spikes/restate/semantics.test.ts` on those versions, on a normal
server and on an always-replay server; re-run it on any upgrade.

Upstream (the official Restate skill, vendored unchanged): `references/upstream/`. Read
`ts-api-and-pitfalls.md` for the API, `design-and-architecture.md` before choosing service types or
keys, `invocation-lifecycle.md` for idempotency, cancel and attach, `debug-applications.md` for
errors. Where this file and upstream differ, this file wins: it's measured on our versions.

## The model, precisely

- **Journaled, exactly once per invocation:** the results of `ctx.run` steps, state (`ctx.get`,
  `ctx.set`), calls and sends to other handlers, `ctx.sleep`, awakeables. On replay these return
  the recorded value; they are not redone. `ctx.rand` is seeded from the invocation id and
  `ctx.date.now()` is consistent across retries (docs), so both are safe in the body.
- **Not journaled, re-executed on every attempt:** everything else in the handler body. Measured:
  a handler with three steps on an always-replay server ran its body **4 times** (once per attempt)
  while each step ran **once**.
- **A step runs at least once.** Its result is recorded only after it returns; a crash in between
  runs it again. Measured: the gateway killed mid-step → that step ran again after restart.
- **Replay checks the code path.** Each context operation is compared with the journal by **kind
  and name** in order. A difference fails the attempt with `RestateError (570) Found a mismatch
  between the code paths taken…` (server-side RT0016), naming the index and the difference
  (`name: first != second`). The invocation then **retries, not fails**: it waits as `ready` for
  its next attempt, and the retry policy eventually pauses it. Measured (asserted on the SDK's
  stderr and the invocation status) both for non-deterministic branching and for new code in place.
- **Step names are part of the contract.** Renaming a step is a mismatch for in-flight invocations,
  exactly like reordering.

## 1. Non-determinism avoidance

Rule: **every decision in the handler body depends only on the handler's input, journaled values
(step results, state, call results), and constants.** Anything else may differ on replay.

Sources of non-determinism, all forbidden in the body (fine inside a step):

| Source | Instead |
|---|---|
| `Date.now()`, `new Date()`, `performance.now()` | `await ctx.date.now()` |
| `Math.random()`, `crypto.randomUUID()`, uuid libs | `ctx.rand.random()`, `ctx.rand.uuidv4()` (not for crypto) |
| `setTimeout`, `setInterval`, timers | `ctx.sleep(...)`, a delayed send |
| Reads from SQLite (memory.db), files, env, config, the network | a step: `await ctx.run("read …", () => …)` |
| Module-level or global variables, caches, counters | state (`ctx.get`/`ctx.set`) or a step result |
| A query without `ORDER BY`, object keys from external data | `ORDER BY` inside the step; sort before returning |
| Native `Promise.all/race/any/allSettled` over context operations | `restate.RestatePromise.all/race/any/allSettled` |
| `Date` objects, `Map`, `Set`, class instances from steps | plain JSON (below) |
| Code that changed under an in-flight invocation | versioning (section 2) |

Measured traps:
- **Branching on outside state** (a module counter): on a normal server the invocation completed
  (the bug stays hidden until a replay); on the always-replay server it failed every attempt with
  570. Only an always-replay test finds it.
- **Mutating an outer variable inside a step** (`let x = 0; await ctx.run(() => { x = 5 }); return
  x`): returned 5 normally, **0 on replay**, silently. A step must **return** what it produced;
  never assign to captured variables.
- **A step's value is JSON round-tripped, on the first run too**: `Date` → ISO string, `Map` → `{}`,
  class instance → plain object (methods gone), `undefined` fields dropped, `undefined` result
  stays `undefined`. Silent data loss, no error. Return plain JSON-safe objects and rebuild
  explicitly (`new Date(iso)`), or give the step a `serde`.
- **A value JSON can't serialize** (BigInt): the error is **not thrown into the handler** (a
  surrounding try/catch never sees it); the invocation sits `ready`, retrying (the policy would
  pause it after its attempts; not waited for). Convert before returning (`String(n)`).
- Native `Promise.all` over two steps happened to complete in both modes in our probe; upstream
  says native combinators aren't journaled and forbids them. Always use `RestatePromise`.
- `ctx.*` inside a step's callback is forbidden (upstream rule, not probed: no `ctx.get`,
  `ctx.run`, `ctx.sleep` inside `ctx.run`).

## 2. Durable recovery

What a recovery restores: the journal (step results, state, sends, timers) and the input; the
handler body runs again from the top. What it doesn't: any process memory, open connections,
anything the body did outside steps.

- **Measured** (`spike.test.ts`): the handler process (gateway) killed mid-job → the job finished
  after restart and the step in flight ran again; restate-server killed mid-job → the jobs finished
  after its restart, each committed once; a self-rescheduling daily chain survived both down for
  4 s with one chain (no duplicate or skipped tick, no two ticks closer than 0.5 s). Observed, not
  asserted: about 6 s and 5 s to finish after the restarts.
- **Inactivity timeout** (default 1 min): if no new journal entry arrives for that long, Restate
  asks the handler to suspend, preserving progress. **Abort timeout** (default 10 min) follows; when
  it expires the invocation is aborted, which can interrupt user code, and the step runs again on
  the next attempt. Any step that can exceed a minute (a model call: allow 3–5 min) needs
  `inactivityTimeout`/`abortTimeout` raised on its handler or service (upstream advice; not probed).
- **Retention:** journals 24 h after completion, idempotency keys 24 h, workflow state 24 h. Set
  per service (`journalRetention`, `idempotencyRetention`).
- **Versioning.** An invocation is pinned to the deployment it started on, and retries go there.
  - Measured: **new code in place** (same URL, re-registered with `force`) under an in-flight
    invocation whose code gained a step → 570 on every retry; it never finishes.
  - Measured: **a new deployment beside the old one** (another URL) → the in-flight invocation
    finished on v1 while new calls ran v2.
  - DIANA has one gateway process, so a deploy *is* an in-place change. Rules:
    1. Keep handlers short (seconds to minutes) so a deploy can **drain**: stop enqueueing, wait
       until `restate invocations list` shows none running, deploy, re-register.
    2. Changing a handler's sequence of context operations (add, remove, reorder or rename a step,
       change a call's target, change which branch runs an operation) is a **breaking** change:
       add a new handler (`analyseV2`), send new work there, keep the old one until it drains,
       then remove it. Changing code *inside* a step's callback is safe.
    3. Scheduled work uses **delayed sends**, never long `ctx.sleep` inside a handler (that pins
       it to old code and blocks its key). Measured: a send delayed 3 s, then new code deployed in
       place, ran entirely on the new code: an invocation that hasn't started has no journal to
       mismatch.
    4. A stuck invocation after a bad in-place deploy (570): the deployment id is the same, so
       "resume on another deployment" doesn't apply. Roll the code back (the old operation
       sequence), then it continues; or kill it and let DIANA's daily job re-derive the work.
       `restate invocations resume <id> --deployment <id>` only helps with a second deployment
       whose code takes the same steps as the old up to where it stopped.
- **Recovery is not a reason to keep state in Restate.** memory.db is the source of truth; Restate
  K/V state holds only job control (a chain's `started` flag, a cursor). Anything Restate loses (its
  data directory) must be re-derivable from memory.db (the daily job does this, R-8.13).

## 3. Task separation

- **One side effect per step**, and a step is the unit that repeats. If a step does two things and
  dies after the first, both run again. Split them.
- **Decide, then commit.** A model call is one step; the write to memory.db is another. Never put
  the model call inside the transaction's step.
- **Read inside a step when the read drives a branch**; the journaled value then replays
  consistently. But it goes stale: the **commit step re-checks its preconditions** inside its own
  transaction (the memory's revision, the target fact's version, eligibility) and discards when
  they changed. Measured in the spike: changes made mid-job were discarded at commit.
- **One transaction per step, never across steps.** `BEGIN IMMEDIATE … COMMIT` inside one
  `ctx.run`; roll back on error and rethrow.
- **Keys are concurrency.** A virtual object's exclusive handlers run one at a time per key
  (measured: never overlapped). DIANA's analysis queue is one key (the single worker of R-8.11);
  reads go in `restate.handlers.object.shared` handlers.
- **No deadlocks:** an exclusive handler never makes a request-response call to an exclusive
  handler of the same key (or any cycle of them); use a one-way send. Map the call graph first.
- **Short invocations.** Long work is chunked: each chunk does its part and sends the next.
- **Service types:** Service (stateless, parallel), Virtual Object (keyed, single writer), Workflow
  (once per id, with promises). See `references/upstream/design-and-architecture.md`.

## 4. Retry logic

Three layers; never add a fourth (no manual retry loops, no retry counters in state).

| Layer | Configure | When exhausted | Measured |
|---|---|---|---|
| A step | `ctx.run(name, fn, { maxRetryAttempts, maxRetryDuration, initialRetryInterval, retryIntervalFactor, maxRetryInterval })` | `TerminalError` thrown **into the handler**, original message kept, catchable | 3 attempts, then `TerminalError: Connection error.` caught |
| The invocation | `retryPolicy: { initialInterval, maxInterval, maxAttempts, onMaxAttempts: "pause" \| "kill" }` on the service (`options`) or handler (`restate.handlers.handler({...}, fn)`) | `pause`: waits for an operator; `kill`: fails, **skips compensations** | 3 attempts → `paused`; with kill → failed `[500] boom` |
| Server default | `[default-retry-policy]` | — | 1.8.1: 500 ms × 2 up to 1 min, **70 attempts (~1 h), then pause** |

- **Errors:** any thrown error is retryable. `restate.TerminalError(message, { errorCode })` stops
  retrying at once and returns to the caller (measured: one attempt, HTTP 409 with the message).
  `restate.RetryableError(message, { retryAfter })` sets the next delay (a `Retry-After` header).
- **Classify at the edge:** inside a step, turn known-permanent failures (validation, 4xx other than
  429, a model's unreadable answer that a retry won't fix) into `TerminalError`; let transient ones
  (connection errors, 5xx, 429) throw.
- **Bound model calls:** a step calling a model gets `maxRetryAttempts` (e.g. 5) so a provider
  outage ends in a caught `TerminalError` the handler handles (leave the memory queued for the daily
  job, record why), instead of an invocation retrying for an hour.
- **Cancellation** (CLI, UI, `ctx.cancel`) throws a `TerminalError` at the next context await; undo
  earlier steps there (saga) and rethrow.
- **Paused invocations need an operator:** `restate invocations list --status paused --json`, then
  resume or kill. DIANA's admin surface should show them.
- **A self-rescheduling chain sends its next run first**, before its risky work: if the work runs
  out of retries (paused or killed), the chain still continues. Bound the work's retries and catch
  the `TerminalError` so the run completes. To restart a chain that died anyway without doubling a
  live one, have every run (and the gateway at start-up) send the next run with the same
  idempotency key for its due slot (e.g. `daily-2026-11-03`): duplicates within the idempotency
  retention collapse into one. (Design guidance; the slot key isn't probed yet.)

## 5. Side-effect avoidance

A side effect outside a step runs again on every attempt (measured: 4× for a three-step handler on
replay). A side effect inside a step runs at least once. So:

- **Nothing observable in the handler body:** no DB writes, no files, no HTTP, no WebSocket or
  event-bus notices, no metrics, no in-memory mutations that outlive the call.
- **Logging:** `ctx.console` (suppressed on replay: measured 1 line for 4 attempts); plain
  `console.log` printed 4 times. Gateway logs from handlers go through `ctx.console`, never the
  gateway logger directly.
- **Every step idempotent**, because it may run twice:
  - inserts keyed by a natural unique key (`UNIQUE (memory, rev)`, `INSERT OR IGNORE`);
  - updates guarded by a version or revision check;
  - external calls with an idempotency key that is the same on every attempt: derived from the
    input (`m<id>r<rev>`), or `ctx.request().id` (the invocation id) plus the step's name, or
    `ctx.rand.uuidv4()` taken *before* the step;
  - notices (memory.changed) sent from inside the commit step, after the commit, and harmless when
    repeated (they carry only an id).
- **Enqueue with idempotency keys** so a repeated send is the same job: `idempotency-key:
  m<memory>r<rev>` for an analysis, a day stamp for a daily job.
- **The journal is data at rest, outside memory.db.** Step results are stored by restate-server
  for the journal retention. In DIANA: steps return ids, revisions and decisions, not memory text,
  where they can; model inputs are read inside the step that uses them; journal retention stays
  short; **confidential and incognito sessions never enqueue anything** (D-62); secrets never pass
  through a step, a state key or a step name.

## Testing (mandatory)

- **Always replay** every handler change: run restate-server with
  `RESTATE_WORKER__INVOKER__INACTIVITY_TIMEOUT=0m` (replays after every step). Non-determinism and
  mutation bugs fail there and pass on a normal server.
- The harness pattern is `spikes/restate/harness.ts`: the real `restate-server` binary from npm
  (no containers: disk is tight), own ports (`RESTATE_INGRESS__BIND_ADDRESS`,
  `RESTATE_ADMIN__BIND_ADDRESS`, `RESTATE_BIND_ADDRESS`), own `--base-dir`, `--listen-mode tcp`
  (unix socket paths over ~100 chars fail), register with `POST /deployments`, check state with the
  admin `POST /query` SQL (`sys_invocation`: status, completion_result, completion_failure).
- Tests for a job include: each crash point (kill the handler process mid-step, kill the server),
  a precondition changed mid-job (discarded at commit), retries exhausted (the handler's
  `TerminalError` path), a duplicate enqueue (one job), and the versioning rule if handlers change.
- Upstream's Testcontainers scaffold (`RestateTestEnvironment`, `alwaysReplay: true`) is the
  equivalent with Docker; we don't use it.

## Server configuration (DIANA)

`disable-telemetry = true` (on by default); the web UI off; `default-num-partitions` small (2);
`rocksdb-total-memory-size` 256 MiB, `[admin.query-engine] memory-size` 64 MiB and
`[worker.invoker] memory-limit` 256 MiB (defaults 2 GiB, 1 GiB, 1.5 GiB): measured 167 MiB
resident (`spikes/restate/restate.toml`). Bound to 127.0.0.1, ports set explicitly (the default
ingress 8080 is common). Install the server binary without running npm install scripts
(`@scarf/scarf` is install analytics).

**The handler endpoint accepts any caller** (the SDK warns: "Accepting requests without
validating request signatures"). Anyone who reaches it can run any handler. Bind it to 127.0.0.1,
and turn on request signing: the server signs with a request-identity private key, the endpoint
checks with `identityKeys: ["publickeyv1_…"]` in its options (SDK option verified in the types;
the pairing isn't tested yet: Phase 37e).

## Before you finish

- [ ] Every side effect, read that drives a branch, and model call is in its own named step.
- [ ] No time, randomness, timers, globals, env/config or DB reads in the handler body.
- [ ] Steps return plain JSON; no captured-variable mutation; nothing JSON can't carry.
- [ ] `RestatePromise` combinators only; no `ctx.*` inside a step.
- [ ] Every step idempotent; the commit step re-checks preconditions in one transaction.
- [ ] Retries bounded where a human or the daily job should take over; `TerminalError` for
      permanent failures; no manual retry loops.
- [ ] `ctx.console` for logs; no notices or metrics from the body.
- [ ] Timeouts raised for steps that can pass a minute.
- [ ] Changing an existing handler's operation sequence? New handler name, drain plan.
- [ ] Exclusive-handler call graph has no cycle and no same-key request-response.
- [ ] Journal content checked: ids over text; nothing from confidential sessions; no secrets.
- [ ] Always-replay test plus crash tests pass; output shown, not assumed.
