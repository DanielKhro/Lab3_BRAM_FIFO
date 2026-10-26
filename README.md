# Overview
This lab describes the design and verification of a single-clock FIFO that stores data in the Block RAM of an FPGA. This FIFO like any FIFO accepts the read and write requests, contains status flags to maintain proper operation and prevent unintended hardware behavior. There's also a tracker that stores the number of words in the FIFO which signals all the flags. 

# Design Summary
The design implements a single-clock FIFO with 32 storage locations, each holding a 16-bit word. Simple dual port block RAM (BRAM) provides separate write and read addresses which allows the FIFO to accept both operations on the same clock cycle. Write and read pointers will assist in choosing the locations. The variable data_count will track the number of stored words. Writes are ignored when the FIFO is full, whereas reads are ignored when the FIFO is empty. The flags empty, full, almost_empty, and almost_full are all reliant on data_count so the functionality of it must be ensured through simulation. Synchronous Reset or SRST clears the write pointer, read pointer, data_count, and the data pipeline. The latency is configurable up to 8 so I just tested it on 8. 

![alt text](FIFO_Block_Diagram.png)

![alt text](Schematic_FIFO.png)

# Verification and Results w/ Test Cases 
A self checking verilog testbench was used with a 50MHz clock, 16-bit data width, 32 words depth, and read latency of 8. The tb references the FIFO and compares expected data, valid signal, data count, and status flags after each step. If the values are wrong, as in they are not the expected result, the console will report it. 

The test began with a reset and an attempted read while the FIFO was empty. It then wrote and read 0xFFFF and 0x0000 to check all-one and all-zero data, followed by the alternating patterns 0xAAAA and 0x5555. These values were supplied through input_data.txt. The test also included cycles with both enable signals low to verify that the FIFO does not change when no operation is requested.

To reflect full memory, the tb wrote 32 words. From this I was able to verify the flags such as empty, almost_empty, almost_full, and full against the expected word count. Also the write was ignored when the full flag was enabled. The tests also checked simultaneous read and write if both are enabled. This went over if the FIFO was full, partially filled, and empty. 

The testbench also verified the functionality of reset after FIFO activity. Output returned to zero after reset clock edge and queued word could no longer be read. Accepted reads, the tb checked that valid and corresponding data appeared after the 8 cycle read latency.

Overall, the simulation passed while meeting all its criteria. Block RAM was also used correctly as utilization report did report BRAM to be selected. Screenshot of this is also posted below.

Almost Full with attempted write:
![alt text](Almost_full_and_full_active_writing_BEAD.png)

Alternating Bit Patterns:
![alt text](Alternating_bit_patterns_write_read.png)

Empty and Almost Empty Flags:
![alt text](Empty_and_Almost_Empty_Active.png)

Read and Write Enable Signals:
![alt text](Read_and_Write_Enable_Signals.png)

SRST Verification:
![alt text](SRST_Output_0_Verif.png)

Writing Ones and Zeros Reading:
![alt text](Writing_ones_and_zeros_reading.png)

Passing Custom Generated Data into FIFO:
![alt text](Passing_with_custom_gen_data.png)

BRAM Verification in Utilization Report:
![alt text](BRAM_Utilization_Report.png)

# Known Issues or Limitations:
Something that took me awhile was inferring the BRAM properly as well as getting the python tcl scripts to run. It took me a lot of time adjusting to the scripting procedures but nonetheless I eventually realized how it connected with Vivado. Inferring the BRAM was more of a syntax issue which I solved after ensuring my ports were referenced correctly and the data signals were correct. It actually came down to the initialization.

# References:
- GitHub multiplier_example (https://github.com/csun-fall26-ece-520/ECE520_Lab_Misc)

- https://chipverify.com/verilog/verilog-math-functions

- BRAM Guide (https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Block-RAM)

- BRAM Init (https://docs.amd.com/r/2023.1-English/ug901-vivado-synthesis/RAM-HDL-Coding-Techniques)