A UVM environment that verifies a simplified AXI4 slave (`axi4`) with an internal
1024 x 32-bit synchronous memory (`axi4_memory`). The environment has an **active AXI agent**
and a **passive memory agent**, each with its own scoreboard and coverage collector, so a
bug can be localised to the AXI-protocol side or the memory side of the DUT.

> Status: environment builds and runs clean against `Fixed_RTL`. Directed reset, write/read
> and corner-address tests pass. Error-path tests, SVA, random/burst tests, factory override,
> virtual sequencer and RAL are **not implemented yet** (see [Status](#status)).

---

## 1. Folder layout

```
AXI4 Verification/
├── Buggy_RTL/              Original design with the injected bugs (kept for before/after runs)
│   ├── axi4.v
│   └── axi_memory.v
├── Fixed_RTL/              Design after fixes -- this is what axi_files.list compiles
│   ├── axi4.v
│   └── axi_memory.v
├── axi_if.sv               AXI interface (MASTER / SLAVE / MONITOR modports)
├── mem_if.sv               Passive memory-bus interface (MONITOR modport), attached with `bind`
├── common_cfg_pkg.sv       Shared config objects passed test -> env
├── axi_transaction_pkg.sv  axi_transaction (reset / write / read, burst-capable)
├── mem_transaction_pkg.sv  mem_transaction (one sample per memory-bus clock)
├── axi_sequence_pkg.sv     Sequences
├── axi_sequencer_pkg.sv
├── axi_driver_pkg.sv       Drives AW/W/B/AR/R and reset; burst-general
├── axi_monitor_pkg.sv      Rebuilds write/read/reset transactions from the pins
├── mem_monitor_pkg.sv      Samples mem_en/we/addr/wdata/rdata every clock
├── axi_agent_pkg.sv        Active agent  (driver + sequencer + monitor)
├── mem_agent_pkg.sv        Passive agent (monitor only)
├── axi_scoreboard_pkg.sv   Shadow-memory model fed from the AXI side
├── mem_scoreboard_pkg.sv   Independent shadow-memory model fed from the memory bus
├── axi_coverage_pkg.sv     AXI functional coverage
├── mem_coverage_pkg.sv     Memory functional coverage
├── axi_env_pkg.sv          Environment (wires monitors -> scoreboards + coverage)
├── axi_test_pkg.sv         Tests
├── axi_pkg.sv              Umbrella package
├── axi_top.sv              Top module: clock, interfaces, DUT, bind, config_db, run_test
├── axi_files.list          Compile order
├── run.do                  Single-run flow (compile, simulate with +acc, load waves)
├── wave.do                 Wave layout (AXI channels grouped by divider, memory probe group)
├── axi4.drawio             Architecture diagram
└── AXI4_Verification_Plan.xlsx   Verification plan (see section 6)
```

## 2. Architecture

```
<img width="831" height="662" alt="image" src="https://github.com/user-attachments/assets/c50dfc3e-4a7c-4f7d-8d08-72cb1de4f6b9" />

```

Key design decisions:

- **Two independent checkers.** `axi_scoreboard` and `mem_scoreboard` each keep their *own*
  shadow memory. If they disagree, the bug is localised to one side instead of both
  checkers failing the same way on a shared-model bug.
- **Monitors never touch the driver's item.** Each monitor rebuilds transactions from the pins,
  so driver-vs-DUT mismatches are visible.
- **Memory agent is passive by construction.** It has no driver or sequencer class; `mem_if` is
  attached with `bind` into `axi4_memory`, so the RTL is not modified and the interface only has
  a `MONITOR` modport.
- **One item type, three operations.** `axi_transaction.operation_type` is
  `AXI_RESET | AXI_WRITE | AXI_READ`. Reset goes through the sequencer/driver
  (`reset_cycles`, 3-6), not as a random field on every item.
- **Burst-general driver/monitor/scoreboards.** Beat count is always `AWLEN+1` / `ARLEN+1`;
  single-beat is just a 1-iteration burst. `burst_en = 0` (default) forces `AWLEN = ARLEN = 0`;
  `burst_en = 1` allows 0..`MAX_BURST_LEN-1` (15).
- **Memory read latency.** `axi4_memory` has a registered read output (one-cycle latency).
  `mem_scoreboard` therefore checks a read's data on the cycle *after* the request
  (`pending_read`).

## 3. Running

Requires QuestaSim (developed on 2021.1 with the built-in UVM 1.1d).

```tcl
# from the project folder, in the Questa transcript
do run.do
```

`run.do` compiles with `+cover -covercells`, starts `work.axi_top` with
`+UVM_TESTNAME=axi_base_test`, loads `wave.do`, and runs to completion.

- Pick a test: `+UVM_TESTNAME=<test_name>` (it overrides the `run_test("axi_base_test")` in `axi_top.sv`).
- Always use `-voptargs="+acc"` or signals such as `AWVALID` will be optimised out of the wave window.
- Compile order is in `axi_files.list` (RTL, interfaces, config, transactions, sequences, sequencer,
  monitors, driver, agents, scoreboards, coverage, env, tests, `axi_pkg`, `axi_top`).

**Regression with seed sweeps.** A separate `run_regression.do` loops tests x seeds
(`-sv_seed`), writes one log + UCDB per run, merges coverage, writes text/HTML reports and a
PASS/FAIL summary. It is not part of this archive yet; copy it next to `run.do` and run
`do run_regression.do`. Pin `seed_list` inside it to replay a failing seed.

**Switching RTL.** `axi_files.list` points at `Fixed_RTL/`. To reproduce the original bugs, change
the first two lines to `Buggy_RTL/axi4.v` and `Buggy_RTL/axi_memory.v`.
(Note: the file in `Buggy_RTL/` is named `axi_memory.v`; the module inside is `axi4_memory`.)

## 4. What is implemented

**Test:** `axi_base_test` runs, in order, `axi_reset_seq` -> `axi_write_read_seq` -> `axi_corner_addr_seq`.
It is currently a stimulus-driving test, not the abstract environment-only base the plan describes.

**Sequences** (`axi_sequence_pkg.sv`):

| Sequence | What it does |
|---|---|
| `axi_base_sequence` | Empty abstract parent |
| `axi_reset_seq` | One reset pulse (3-6 cycles) through the sequencer/driver |
| `axi_write_read_seq` | Random legal word-aligned address + data: write, then read back |
| `axi_corner_addr_seq` | Write/read at word addresses 0, 14, 15, 16, 30, 31, 1023 with all-ones / zero / walking patterns |

**Checks:**

- AXI side: per-beat read data vs shadow memory, BRESP/RRESP legality (OKAY vs SLVERR from
  range and 4 KB-boundary rules), WDATA/RDATA beat-count sanity, `WLAST`/`RLAST` placement
  warnings in the monitor.
- Memory side: shadow-memory read check (one-cycle latency aware), reset-content check
  (`mem_rdata` must be 0 while `ARESETn` is low), no write/read while in reset, address range.

**Coverage:** `axi_coverage` (op, burst_en, lengths, sizes, responses, address regions, reset
cycles, per-beat data patterns, crosses) and `mem_coverage` (enable, we, address corners,
write/read data patterns, access-during-reset, address x we cross).

## 5. Bugs found

| ID | Location | What | Evidence | Status |
|---|---|---|---|---|
| BUG-01 | `axi_memory.v` | Reset polarity inverted (`if (rst_n)` cleared on the wrong level) | Code review; fixed in `Fixed_RTL` (async active-low reset, also clears the array) | Fixed. **Capture a before/after run against `Buggy_RTL` for the report** |
| BUG-02 | `axi_memory.v` | Read of `mem_addr-1` masked to 28 bits when `mem_addr % 15 == 0` | `axi_corner_addr_seq`: word addr 0 returned `0x0xxxxxxx`, word addr 15 returned `0x0` (addresses 14/16/30/31/1023 clean); both scoreboards agreed | Fixed (read is now `memory[mem_addr]`); clean rerun: 16/16 AXI, 19/19 MEM |
| BUG-04 | `axi4.v` | Read FSM captured `mem_rdata` one cycle early (stale/zero data on read) | First write->read test: AXI read mismatch while memory bus showed correct data one cycle later | Fixed (`R_WAIT` state added) |

`Fixed_RTL` vs `Buggy_RTL` differences are limited to: reset polarity + array clear + read masking in
`axi_memory.v`, and the `R_WAIT` state in `axi4.v`. **BUG-03, 05, 06, 07, 08 from the plan are
unchanged in `Fixed_RTL` and have not been exercised** — in particular BUG-03 (4 KB boundary check uses
`burst_len << size` instead of `(burst_len+1) << size`), which only shows up with bursts or
boundary-crossing accesses. `AXI4_Verification_Plan.xlsx` -> `Bug Watchlist` still lists every
bug as "Suspected"; update it.

## 6. Verification plan workbook

`AXI4_Verification_Plan.xlsx` sheets: `RTM` (26 requirements), `Test Plan`, `Sequences`,
`Test Cases`, `CRT Plan`, `Func Cov`, `SVA`, `Bug Watchlist`, `Legends`. The plan describes more
than is built; use it as the target list. Status columns are still "Pending".

## 7. Status

| Item | State |
|---|---|
| Active AXI agent, passive memory agent, monitors, scoreboards, coverage, env | Done |
| Reset, write/read, corner-address directed tests | Done, passing on `Fixed_RTL` |
| Waveform setup (`wave.do`) | Done |
| Error-path sequences (out-of-range, 4 KB crossing) | **Not done** |
| Reset during a live transfer | **Not done** |
| Constrained-random sequence (`axi_random_rw_seq`) and burst sequences | **Not done** (randomization today is only `axi_write_read_seq` address/data and reset width) |
| SVA / assertion coverage | **Not done** (no assertions in the archive) |
| Factory override (`axi_driver_delay`, `set_type_override_by_type`, topology before/after) | **Not done** (required by the project spec) |
| Virtual sequencer / virtual sequences | **Not done** |
| RAL model (frontdoor/backdoor) | **Not done** |
| Merged multi-seed coverage report, coverage closure | **Not done** |
| Back-pressure (BREADY/RREADY/VALID delays) | **Not done** (driver holds `BREADY`/`RREADY` high) |

## 8. Known issues / things to watch

1. **Scoreboards do not clear their shadow memory on reset**, but `Fixed_RTL` clears the memory array
   on reset. A reset in the middle of a test (the planned reset-during-transfer test) will produce
   false read mismatches until both scoreboards clear on `AXI_RESET` / `ARESETn == 0`.
2. **Burst runs will disagree with the DUT on 4 KB crossings** because the scoreboard computes
   legality with `(beats x 4)` while the DUT's check is off by one beat (BUG-03). That mismatch is a
   real finding, not a scoreboard bug.
3. `mem_scoreboard` tracks one outstanding read (`pending_read`). Fine for single-beat traffic; revisit
   before back-to-back burst reads.
4. `axi_monitor`'s read watcher ends a read on the observed `RLAST`. If a DUT bug never asserts
   `RLAST`, the monitor waits forever (shows up as a hang). Add a timeout if this bites.
5. Driver handshake waits (`do @(posedge ACLK) while (!READY)`) have no timeout; a stuck handshake
   hangs the simulation instead of failing.
6. Monitors sample after `#1` following the clock edge to avoid same-edge races with driver/DUT
   nonblocking updates; keep that if you modify them.
7. `mem_monitor` logs every clock at `UVM_MEDIUM`, which floods long runs. Move the per-cycle line to
   `UVM_HIGH` before regressions.
8. `run.do` instruments the whole testbench for code coverage. For the code-coverage numbers, report on
   the DUT instances only (`axi4`, `axi4_memory`).
9. The archive contains `.$axi4.drawio.bkp`, a draw.io backup file. Leave it out of the delivery.
