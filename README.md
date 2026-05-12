# Asynchronous FIFO Verification using UVM

## Project Overview

This project implements and verifies an **Asynchronous FIFO** using **SystemVerilog and UVM**. The FIFO supports independent write and read clock domains and uses **binary-to-Gray code pointer conversion**, **two-stage pointer synchronization**, and **full/empty flag generation** to safely transfer data across clock domains.

The verification environment is built using UVM components such as sequence, sequencer, driver, monitors, agent, environment, scoreboard, and test.

---

## Key Features

* Asynchronous FIFO with separate write and read clocks
* Binary pointer and Gray pointer implementation
* Two-flop synchronizers for clock-domain crossing
* Full and empty flag verification
* UVM-based reusable verification environment
* Write-only, read-only, and randomized sequence support
* Scoreboard-based data comparison
* Waveform/result-based verification

---

## FIFO Design Description

The FIFO design contains two independent clock domains:

* **Write clock domain:** Handles write enable, write data, write pointer increment, and full flag logic.
* **Read clock domain:** Handles read enable, read data, read pointer increment, and empty flag logic.

To safely pass pointer information between the write and read clock domains, Gray-coded pointers are synchronized using two-stage synchronizers.

### Main Design Blocks

| Block                     | Description                                         |
| ------------------------- | --------------------------------------------------- |
| Memory Array              | Stores FIFO data                                    |
| Write Pointer             | Tracks write location in binary and Gray code       |
| Read Pointer              | Tracks read location in binary and Gray code        |
| Binary-to-Gray Conversion | Converts binary pointer to Gray code for CDC safety |
| Pointer Synchronizers     | Synchronize Gray pointers across clock domains      |
| Full Logic                | Detects FIFO full condition in write clock domain   |
| Empty Logic               | Detects FIFO empty condition in read clock domain   |

---

## UVM Testbench Architecture

The UVM testbench verifies the FIFO by generating write and read transactions, driving them to the DUT, monitoring DUT behavior, and comparing expected versus actual output data using a scoreboard.

### Framework Design

```text
+-------------------+
|      uvm_test     |
+---------+---------+
          |
          v
+-------------------+
|      uvm_env      |
+---------+---------+
          |
          v
+-------------------+       +-------------------+
|      uvm_agent    | ----> |    Scoreboard     |
+---------+---------+       +-------------------+
          |
          +-----------------------------+
          |                             |
          v                             v
+-------------------+       +-------------------+
|     Sequencer     |       | Write/Read Monitor|
+---------+---------+       +-------------------+
          |
          v
+-------------------+
|      Driver       |
+---------+---------+
          |
          v
+-------------------+
|   Asynchronous    |
|      FIFO DUT     |
+-------------------+
```

---

## UVM Components

### Transaction

The transaction class contains FIFO control and data fields:

```systemverilog
rand bit wr_en;
rand bit rd_en;
rand bit [7:0] wr_data;
bit full;
bit empty;
bit [7:0] rd_data;
```

It also includes constraints to avoid invalid idle transactions during random testing.

---

### Sequences

The testbench includes multiple sequences:

| Sequence | Purpose                                  |
| -------- | ---------------------------------------- |
| `seq1`   | Random write/read transaction generation |
| `seq2`   | Write-only sequence to fill the FIFO     |
| `seq3`   | Read-only sequence to drain the FIFO     |

Example write-only sequence behavior:

```systemverilog
tr.wr_en = 1'b1;
tr.rd_en = 1'b0;
```

Example read-only sequence behavior:

```systemverilog
tr.wr_en = 1'b0;
tr.rd_en = 1'b1;
```

---

### Driver

The driver receives transactions from the sequencer and drives FIFO inputs through the virtual interface.

The driver drives signals on the **negative edge** of the clock to avoid race conditions with the DUT, which samples on the positive clock edge.

```systemverilog
@(negedge vif.wr_clk);
vif.wr_en   <= tr.wr_en;
vif.wr_data <= tr.wr_data;
```

```systemverilog
@(negedge vif.rd_clk);
vif.rd_en <= tr.rd_en;
```

---

### Write Monitor

The write monitor observes valid write operations from the DUT interface and sends captured write transactions to the scoreboard.

A valid write is detected when:

```systemverilog
vif.wr_en && !vif.full
```

---

### Read Monitor

The read monitor observes valid read operations and captures `rd_data` after the DUT updates the output data.

A valid read is detected when:

```systemverilog
vif.rd_en && !vif.empty
```

---

### Scoreboard

The scoreboard maintains a reference queue to model FIFO behavior.

* On a valid write, `wr_data` is pushed into the expected queue.
* On a valid read, the expected data is popped from the queue.
* The scoreboard compares expected data against actual `rd_data` from the DUT.

```systemverilog
fifo_queue.push_back(tr.wr_data);
expected_data = fifo_queue.pop_front();
```

Comparison logic:

```systemverilog
if(expected_data != tr.rd_data) begin
  `uvm_error("SCO", $sformatf("DATA MISMATCH Expected = %0d, Actual = %0d", expected_data, tr.rd_data))
end
else begin
  `uvm_info("SCO", $sformatf("DATA MATCH Expected = %0d, Actual = %0d", expected_data, tr.rd_data), UVM_NONE)
end
```

---

## Test Scenarios

The following scenarios were verified:

| Test Scenario          | Description                             | Status |
| ---------------------- | --------------------------------------- | ------ |
| Reset Test             | Verify FIFO reset behavior              | Passed |
| Write Test             | Write multiple data values into FIFO    | Passed |
| Read Test              | Read data values from FIFO              | Passed |
| FIFO Data Order Test   | Verify first-in-first-out data ordering | Passed |
| Full Condition Test    | Verify FIFO full behavior               | Passed |
| Empty Condition Test   | Verify FIFO empty behavior              | Passed |
| Random Write/Read Test | Verify random FIFO operations           | Passed |

---

## Simulation Result

The scoreboard confirms that the expected write data matches the actual read data from the FIFO.

Example simulation result:

```text
UVM_INFO SCO: DATA MATCH Expected data = <value>, Actual data = <value>
```


Recommended GitHub folder structure:

```text
Asynchronous-FIFO-UVM/
├── README.md
├── rtl/
│   └── asyn_fifo.sv
├── tb/
│   ├── async_if.sv
│   └── async_fifo_uvm_tb.sv
├── sim/
│   └── run.do
├── images/
│   ├── framework_design.png
│   ├── waveform.png
│   └── simulation_result.png
└── docs/
    └── notes.md
```

---

## TestBench Flow Diagram Screenshot



```markdown
(results/testbench_flow_diagram.png)
```

---

## Waveform Screenshot

Add your waveform screenshot here:

```markdown
(results/waveform_result.png)
```

---

## How to Run

### Compile and Run Simulation

Use your simulator command or script. Example:

```bash
vlog async_if.sv asyn_fifo.sv async_fifo_uvm_tb.sv
vsim tb_top
run -all
```

For EDA Playground or similar online tools, compile the DUT, interface, and UVM testbench files together and select UVM/SystemVerilog support.

---

## Files

| File                   | Description                             |
| ---------------------- | --------------------------------------- |
| `asyn_fifo.sv`         | Asynchronous FIFO RTL design            |
| `async_if.sv`          | Interface connecting DUT and UVM TB     |
| `async_fifo_uvm_tb.sv` | UVM testbench components and top module |
| `README.md`            | Project documentation                   |

---

## Skills Demonstrated

This project demonstrates hands-on knowledge of:

* SystemVerilog RTL design
* UVM testbench development
* Clock-domain crossing concepts
* Binary-to-Gray and Gray-to-binary conversion
* FIFO full and empty flag verification
* UVM driver, monitor, sequence, agent, environment, and scoreboard
* Functional verification methodology
* Debugging simulation and timing issues
* Scoreboard-based self-checking verification

---

## Conclusion

This project verifies an asynchronous FIFO using a structured UVM environment. The testbench validates FIFO write/read behavior, full and empty conditions, and FIFO data ordering using a scoreboard-based comparison mechanism.

The project highlights practical ASIC verification skills including UVM component development, CDC-aware FIFO verification, transaction-level modeling, and debug using simulation logs and waveform results.
