# Overview
This lab describes the design and verification of a single-clock FIFO that stores data in the Block RAM of an FPGA. This FIFO like any FIFO accepts the read and write requests, contains status flags to maintain proper operation and prevent unintended hardware behavior. There's also a tracker that stores the number of words in the FIFO which signals all the flags. 

# Design Summary
The design implements a single-clock FIFO with 32 storage locations, each holding a 16-bit word. Simple dual port block RAM (BRAM) provides separate write and read addresses which allows the FIFO to accept both operations on the same clock cycle. Write and read pointers will assist in choosing the locations. The variable data_count will track the number of stored words. Writes are ignored when the FIFO is full, whereas reads are ignored when the FIFO is empty. The flags empty, full, almost_empty, and almost_full are all reliant on data_count so the functionality of it must be ensured through simulation. Synchronous Reset or SRST clears the write pointer, read pointer, data_count, and the data pipeline. The latency is configurable up to 8 so I just tested it on 8. 

<img width="251" height="200" alt="FIFO_Block_Diagram" src="https://github.com/user-attachments/assets/a6cc209f-ffc7-4d34-a400-3eecdf9359ea" />

<img width="349" height="392" alt="Schematic_FIFO" src="https://github.com/user-attachments/assets/4fa4c3c9-aef3-4a01-a1b4-5fc29e772f34" />

# Verification and Results w/ Test Cases 
A self checking verilog testbench was used with a 50MHz clock, 16-bit data width, 32 words depth, and read latency of 8. The tb references the FIFO and compares expected data, valid signal, data count, and status flags after each step. If the values are wrong, as in they are not the expected result, the console will report it. 

The test began with a reset and an attempted read while the FIFO was empty. It then wrote and read 0xFFFF and 0x0000 to check all-one and all-zero data, followed by the alternating patterns 0xAAAA and 0x5555. These values were supplied through input_data.txt. The test also included cycles with both enable signals low to verify that the FIFO does not change when no operation is requested.

To reflect full memory, the tb wrote 32 words. From this I was able to verify the flags such as empty, almost_empty, almost_full, and full against the expected word count. Also the write was ignored when the full flag was enabled. The tests also checked simultaneous read and write if both are enabled. This went over if the FIFO was full, partially filled, and empty. 

The testbench also verified the functionality of reset after FIFO activity. Output returned to zero after reset clock edge and queued word could no longer be read. Accepted reads, the tb checked that valid and corresponding data appeared after the 8 cycle read latency.

Overall, the simulation passed while meeting all its criteria. Block RAM was also used correctly as utilization report did report BRAM to be selected. Screenshot of this is also posted below.

Almost Full with attempted write:
<img width="761" height="281" alt="Almost_full_and_full_active_writing_BEAD" src="https://github.com/user-attachments/assets/fe764e53-6d9c-4f0e-9b84-2322d6409ddc" />

Alternating Bit Patterns:
<img width="900" height="233" alt="Alternating_bit_patterns_write_read" src="https://github.com/user-attachments/assets/11e4473b-481c-4a6c-bd02-690ca2bc40c7" />

Empty and Almost Empty Flags:
<img width="764" height="188" alt="Empty_and_Almost_Empty_Active" src="https://github.com/user-attachments/assets/8aa40625-5078-4df6-8f3d-eaa532f22903" />

Read and Write Enable Signals:
<img width="903" height="88" alt="Read_and_Write_Enable_Signals" src="https://github.com/user-attachments/assets/3ed8a0f5-faae-4d31-b94e-5f1ba390ce02" />

SRST Verification:
<img width="235" height="158" alt="SRST_Output_0_Verif" src="https://github.com/user-attachments/assets/afd94a7a-c0eb-4b8e-a33a-bfa8226a3a8d" />

Writing Ones and Zeros Reading:
<img width="899" height="235" alt="Writing_ones_and_zeros_reading" src="https://github.com/user-attachments/assets/f9d20718-aaac-434f-b711-7ce893e2fe2c" />

Passing Custom Generated Data into FIFO:
<img width="802" height="45" alt="Passing_with_custom_gen_data" src="https://github.com/user-attachments/assets/96730c0d-65af-4118-b6d1-cf5fff6b6642" />

BRAM Verification in Utilization Report:
<img width="467" height="480" alt="BRAM_Utilization_Report" src="https://github.com/user-attachments/assets/9cfe8ceb-1566-485f-a055-4994bf236fed" />

# Known Issues or Limitations:
Something that took me awhile was inferring the BRAM properly as well as getting the python tcl scripts to run. It took me a lot of time adjusting to the scripting procedures but nonetheless I eventually realized how it connected with Vivado. Inferring the BRAM was more of a syntax issue which I solved after ensuring my ports were referenced correctly and the data signals were correct. It actually came down to the initialization.

# References:
- GitHub multiplier_example (https://github.com/csun-fall26-ece-520/ECE520_Lab_Misc)

- https://chipverify.com/verilog/verilog-math-functions

- BRAM Guide (https://docs.amd.com/r/en-US/ug585-zynq-7000-SoC-TRM/Block-RAM)

- BRAM Init (https://docs.amd.com/r/2023.1-English/ug901-vivado-synthesis/RAM-HDL-Coding-Techniques)
