// Every package file is included here by path, in dependency order,
// so axi_pkg.sv is the only file the file list needs for the testbench packages.
`include "tb/axi/axi_transaction_pkg.sv"
`include "tb/mem/mem_transaction_pkg.sv"

`include "tb/axi/axi_agent/axi_sequencer_pkg.sv"
`include "tb/axi/axi_agent/axi_driver_pkg.sv"
`include "tb/axi/axi_agent/axi_monitor_pkg.sv"
`include "tb/axi/axi_agent/axi_agent_pkg.sv"

`include "tb/mem/memory_agent/mem_monitor_pkg.sv"
`include "tb/mem/memory_agent/mem_agent_pkg.sv"

`include "tb/axi/axi_scoreboard_pkg.sv"
`include "tb/mem/mem_scoreboard_pkg.sv"

`include "tb/axi/axi_coverage_pkg.sv"
`include "tb/mem/mem_coverage_pkg.sv"

`include "tb/axi/axi_sequence_pkg.sv"
`include "tb/env/axi_env_pkg.sv"
`include "tb/env/axi_test_pkg.sv"

package axi_pkg;

	import axi_transaction_pkg::*;
	import mem_transaction_pkg::*;
	import common_cfg_pkg::*;
	import axi_sequence_pkg::*;
	import axi_sequencer_pkg::*;
	import axi_monitor_pkg::*;
	import mem_monitor_pkg::*;
	import axi_driver_pkg::*;
	import axi_agent_pkg::*;
	import mem_agent_pkg::*;
	import axi_scoreboard_pkg::*;
	import axi_coverage_pkg::*;
	import mem_scoreboard_pkg::*;
	import mem_coverage_pkg::*;
	import axi_env_pkg::*;
	import axi_test_pkg::*;
	
endpackage : axi_pkg