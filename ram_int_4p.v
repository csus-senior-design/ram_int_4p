/*
--------------------------------------------------
Stereoscopic Vision System
Senior Design Project - Team Honeybadger (Team 11)
California State University, Sacramento
Spring 2015 / Fall 2015
--------------------------------------------------

4 Port Memory Controller Interface
Authors: Padraic Hagerty (guitarisrockin@hotmail.com)

Description:
	This is the four-port memory interface for the Altera Cyclone 5 GX Starter
	Kit. The external memory IP deals with all arbitration, and it provides FIFOs
	for each port. This module abstracts away many of the control signals for the
	hard memory controller IP so the user can simply assert read and write enable
	signals to perform operations in the memory.
	
Instructions:
	This module will have to be instantiated in the top level module for the
	project. The following signals must be brought up through to the top
	level module's IOs: mem_ca, mem_ck, mem_ck_n, mem_cke, mem_cs_n, mem_dm,
	mem_dq, mem_dqs, mem_dqs_n, and oct_rzqin.
	
	You will also have to generate the necessary IP for this memory
	interface. Instructions for generating the IP are located in the
	"C5G LPDDR2 IP Parameters.txt" file. Use the C5G_LPDDR2_Settings.qprs
	file to automatically enter all timing parameters for the IP. MAKE SURE
	TO NAME THE IP "LPDDR2x32_4p" WITHOUT THE QUOTES.
	
	Use the ram_int_4p.qsf file for the pin assignments that are necessary
	for this module.
	
	The PLL IP will probably have to be generated. Make sure it uses a 50MHz
	reference clock, and ensure that the IP name is "PLL" without the quotes.
	When generating the PLL IP, refer to line 119 in this module where the
	PLL is instantiated in order to ensure that the proper ports are
	generated.
	
	Refer to the frame_buf_alt_tb.v file for an example of how to connect the
	frame buffer module to this module.
*/

`ifndef ASSERT_L
`define ASSERT_L 1'b0
`define DEASSERT_L 1'b1
`endif
`ifndef ASSERT_H
`define ASSERT_H 1'b1
`define DEASSERT_H 1'b0
`endif

`timescale 1 ns / 1 ps

module ram_int_4p #(
	parameter	DATA_WIDTH = 32,
				ADDR_WIDTH = 29,
				MEM_DEPTH = 1 << ADDR_WIDTH,
				BE = 4'h7
)(
		input       [ADDR_WIDTH - 1:0]	wr_addr0,
										rd_addr0,
										wr_addr1,
										rd_addr1,
										wr_addr2,
										rd_addr2,
										wr_addr3,
										rd_addr3,
		input		[DATA_WIDTH - 1:0]	wr_data0,
										wr_data1,
										wr_data2,
										wr_data3,
		input							clk_50m,
										clk,
										wr_en0,
										wr_en1,
										wr_en2,
										wr_en3,
										rd_en0,
										rd_en1,
										rd_en2,
										rd_en3,
										reset,
		output							rd_data_valid0,
										rd_data_valid1,
										rd_data_valid2,
										rd_data_valid3,
		output 	reg						wr_rdy0,
										rd_rdy0,
										wr_rdy1,
										rd_rdy1,
										wr_rdy2,
										rd_rdy2,
										wr_rdy3,
										rd_rdy3,
		output	reg	[DATA_WIDTH - 1:0]	rd_data0,
										rd_data1,
										rd_data2,
										rd_data3,
		output	wire	[9:0]			mem_ca,
		output	wire	[0:0]			mem_ck,
		output	wire	[0:0]			mem_ck_n,
		output	wire	[0:0]			mem_cke,
		output	wire	[0:0]			mem_cs_n,
		output	wire	[3:0]			mem_dm,
		inout	wire	[31:0]			mem_dq,
		inout	wire	[3:0]			mem_dqs,
		inout	wire	[3:0]			mem_dqs_n,
		input	wire					oct_rzqin
	);
	
	/* Define the required states. */
	localparam
		INIT = 2'h0,
		IDLE = 2'h1,
		WRITE = 2'h2,
		READ = 2'h3;

	/* Make necessary declarations for the hard memory controller IP. */
	wire          pll_locked_ddr/*, pll_locked_int*/;
	//wire         pll0_pll_clk_clk;
	
	reg				avl_burstbegin_0;
	wire			avl_ready_0;
	reg				avl_ready_0_fl;
	reg		[28:0]	avl_addr_0;
	reg				avl_read_req_0;
	wire	[3:0]	avl_be_0;
	wire			avl_rdata_valid_0;
	reg				avl_write_req_0;
	reg		[2:0]	avl_size_0;
	
	reg				avl_burstbegin_1;
	wire			avl_ready_1;
	reg		[28:0]	avl_addr_1;
	reg				avl_read_req_1;
	wire	[3:0]	avl_be_1;
	wire			avl_rdata_valid_1;
	reg				avl_write_req_1;
	reg		[2:0]	avl_size_1;
	
	reg				avl_burstbegin_2;
	wire			avl_ready_2;
	reg		[28:0]	avl_addr_2;
	reg				avl_read_req_2;
	wire	[3:0]	avl_be_2;
	wire			avl_rdata_valid_2;
	reg				avl_write_req_2;
	reg		[2:0]		avl_size_2;
	
	reg				avl_burstbegin_3;
	wire			avl_ready_3;
	reg		[28:0]	avl_addr_3;
	reg				avl_read_req_3;
	wire	[3:0]	avl_be_3;
	wire			avl_rdata_valid_3;
	reg				avl_write_req_3;
	reg		[2:0]	avl_size_3;
	
	wire			rst_controller_reset_out_reset;
	wire			pll0_reset_out_reset;
	wire			rst_controller_001_reset_out_reset;
	wire			rst_controller_002_reset_out_reset;
	wire			rst_controller_003_reset_out_reset;
	wire			rst_controller_004_reset_out_reset;
	wire			rst_controller_005_reset_out_reset;
	wire			rst_controller_006_reset_out_reset;
	wire			rst_controller_007_reset_out_reset;
	wire			rst_controller_008_reset_out_reset;
	wire			rst_controller_009_reset_out_reset;
	wire			rst_controller_010_reset_out_reset;
	wire			rst_controller_011_reset_out_reset;
	
	wire			local_cal_fail,
					local_cal_success,
					local_init_done;
	reg				local_cal_success_fl;
	reg				global_reset_n,
					soft_reset_n;
	reg		[28:0]	prev_wr_addr0,
					prev_rd_addr0,
					prev_wr_addr1,
					prev_rd_addr1,
					prev_wr_addr2,
					prev_rd_addr2,
					prev_wr_addr3,
					prev_rd_addr3;
	
	(* syn_encoding = "safe" *)
	reg		[1:0]	curr_state0,
					curr_state1,
					curr_state2,
					curr_state3;
	
	/* Assign valid read data signals */
	assign rd_data_valid0 = avl_rdata_valid_0;
	assign rd_data_valid1 = avl_rdata_valid_1;
	assign rd_data_valid2 = avl_rdata_valid_2;
	assign rd_data_valid3 = avl_rdata_valid_3;
			
	/* Begin port 0 interface logic */
	always @(posedge clk) begin
		local_cal_success_fl <= local_cal_success;
		avl_ready_0_fl <= avl_ready_0;
		
		if (reset == `ASSERT_L) begin
			global_reset_n <= `ASSERT_L;
			soft_reset_n <= `ASSERT_L;
			curr_state0 <= INIT;
			
			avl_burstbegin_0 <= `DEASSERT_H;
			avl_size_0 <= 3'h1;
			avl_read_req_0 <= `DEASSERT_H;
			avl_write_req_0 <= `DEASSERT_H;
			avl_addr_0 <= {ADDR_WIDTH{1'b0}};
			
			prev_rd_addr0 <= {ADDR_WIDTH{1'h0}};
			prev_wr_addr0 <= {ADDR_WIDTH{1'h0}};
			
			wr_rdy0 <= `DEASSERT_H;
			rd_rdy0 <= `DEASSERT_H;
		end else
		
		case (curr_state0)
			INIT: begin
				global_reset_n <= `DEASSERT_L;
				if (pll_locked_ddr == `ASSERT_H/* &&
							pll_locked_int == `ASSERT_H*/) begin
					soft_reset_n <= `DEASSERT_L;
					curr_state0 <= INIT;
				end else
					curr_state0 <= INIT;
				if (local_cal_success_fl == `ASSERT_H &&
							soft_reset_n == `DEASSERT_L)
					curr_state0 <= IDLE;
				else
					curr_state0 <= INIT;
			end
						
			IDLE: begin
				avl_write_req_0 <= `DEASSERT_H;
				avl_read_req_0 <= `DEASSERT_H;
				
				wr_rdy0 <= `DEASSERT_H;
				rd_rdy0 <= `DEASSERT_H;
					
				if (avl_ready_0_fl == `ASSERT_H && wr_en0 == `ASSERT_L
							&& prev_wr_addr0 != wr_addr0
							&& rd_en0 == `DEASSERT_L) begin
					curr_state0 <= WRITE;
					wr_rdy0 <= `ASSERT_H;
				end else if (avl_ready_0_fl == `ASSERT_H && rd_en0 == `ASSERT_L 
									&& prev_rd_addr0 != rd_addr0
									&& wr_en0 == `DEASSERT_L) begin
					curr_state0 <= READ;
					rd_rdy0 <= `ASSERT_H;
				end else
					curr_state0 <= IDLE;
			end
			
			WRITE: begin
				wr_rdy0 <= `ASSERT_H;
				rd_rdy0 <= `DEASSERT_H;

				if (avl_ready_0 == `ASSERT_H && wr_en0 == `ASSERT_L
							 && rd_en0 == `DEASSERT_L) begin
					avl_write_req_0 <= `ASSERT_H;
					avl_addr_0 <= wr_addr0;
					prev_wr_addr0 <= avl_addr_0;
				end
				
				if (rd_en0 == `ASSERT_L || (rd_en0 == `ASSERT_L &&
							wr_en0 == `ASSERT_L)) begin
					curr_state0 <= READ;
					rd_rdy0 <= `ASSERT_H;
					wr_rdy0 <= `DEASSERT_H;
				end else if (wr_en0 == `ASSERT_L)
					curr_state0 <= WRITE;
				else
					curr_state0 <= IDLE;
			end
			
			READ: begin
				rd_rdy0 <= `ASSERT_H;
				wr_rdy0 <= `DEASSERT_H;

				if (avl_ready_0 == `ASSERT_H && rd_en0 == `ASSERT_L
							 && wr_en0 == `DEASSERT_L) begin
					avl_read_req_0 <= `ASSERT_H;
					avl_addr_0 <= rd_addr0;
					prev_rd_addr0 <= avl_addr_0;
				end
				
				if (wr_en0 == `ASSERT_L || (rd_en0 == `ASSERT_L &&
								wr_en0 == `ASSERT_L)) begin
					curr_state0 <= WRITE;
					wr_rdy0 <= `ASSERT_H;
					rd_rdy0 <= `DEASSERT_H;
				end else if (rd_en0 == `ASSERT_L)
					curr_state0 <= READ;
				else
					curr_state0 <= IDLE;
			end
		endcase
	end
	/* End port 0 interface logic */
	
	/* Begin port 1 interface logic */
	always @(posedge clk) begin
		if (reset == `ASSERT_L) begin
			curr_state1 <= IDLE;
			
			avl_burstbegin_1 <= `DEASSERT_H;
			avl_size_1 <= 3'h1;
			avl_read_req_1 <= `DEASSERT_H;
			avl_write_req_1 <= `DEASSERT_H;
			
			prev_rd_addr1 <= {ADDR_WIDTH{1'h0}};
			prev_wr_addr1 <= {ADDR_WIDTH{1'h0}};
			
			wr_rdy1 <= `DEASSERT_H;
			rd_rdy1 <= `DEASSERT_H;
		end else
		
		case (curr_state1)
			IDLE: begin
				avl_write_req_1 <= `DEASSERT_H;
				avl_read_req_1 <= `DEASSERT_H;
				
				wr_rdy1 <= `DEASSERT_H;
				rd_rdy1 <= `DEASSERT_H;
					
				if (avl_ready_1 == `ASSERT_H && wr_en1 == `ASSERT_L
							&& prev_wr_addr1 != wr_addr1
							&& rd_en1 == `DEASSERT_L) begin
					curr_state1 <= WRITE;
					wr_rdy1 <= `ASSERT_H;
				end else if (avl_ready_1 == `ASSERT_H && rd_en1 == `ASSERT_L 
									&& prev_rd_addr1 != rd_addr1
									&& wr_en1 == `DEASSERT_L) begin
					curr_state1 <= READ;
					rd_rdy1 <= `ASSERT_H;
				end else
					curr_state1 <= IDLE;
			end
			
			WRITE: begin
				wr_rdy1 <= `ASSERT_H;
				rd_rdy1 <= `DEASSERT_H;

				if (avl_ready_1 == `ASSERT_H && wr_en1 == `ASSERT_L
							 && rd_en1 == `DEASSERT_L) begin
					avl_write_req_1 <= `ASSERT_H;
					avl_addr_1 <= wr_addr1;
					prev_wr_addr1 <= avl_addr_1;
				end
				
				if (rd_en1 == `ASSERT_L || (rd_en1 == `ASSERT_L &&
							wr_en1 == `ASSERT_L)) begin
					curr_state1 <= READ;
					rd_rdy1 <= `ASSERT_H;
					wr_rdy1 <= `DEASSERT_H;
				end else if (wr_en1 == `ASSERT_L)
					curr_state1 <= WRITE;
				else
					curr_state1 <= IDLE;
			end
			
			READ: begin
				rd_rdy1 <= `ASSERT_H;
				wr_rdy1 <= `DEASSERT_H;

				if (avl_ready_1 == `ASSERT_H && rd_en1 == `ASSERT_L
							 && wr_en1 == `DEASSERT_L) begin
					avl_read_req_1 <= `ASSERT_H;
					avl_addr_1 <= rd_addr1;
					prev_rd_addr1 <= avl_addr_1;
				end
				
				if (wr_en1 == `ASSERT_L || (rd_en1 == `ASSERT_L &&
								wr_en1 == `ASSERT_L)) begin
					curr_state1 <= WRITE;
					wr_rdy1 <= `ASSERT_H;
					rd_rdy1 <= `DEASSERT_H;
				end else if (rd_en1 == `ASSERT_L)
					curr_state1 <= READ;
				else
					curr_state1 <= IDLE;
			end
							
			default:  curr_state1 <= IDLE;
		endcase
	end
	/* End port 1 interface logic */
	
	/* Begin port 2 interface logic */
	always @(posedge clk) begin
		if (reset == `ASSERT_L) begin
			curr_state2 <= IDLE;
			
			avl_burstbegin_2 <= `DEASSERT_H;
			avl_size_2 <= 3'h1;
			avl_read_req_2 <= `DEASSERT_H;
			avl_write_req_2 <= `DEASSERT_H;
			
			prev_rd_addr2 <= {ADDR_WIDTH{1'h0}};
			prev_wr_addr2 <= {ADDR_WIDTH{1'h0}};
			
			wr_rdy2 <= `DEASSERT_H;
			rd_rdy2 <= `DEASSERT_H;
		end else
		
		case (curr_state2)
			IDLE: begin
				avl_write_req_2 <= `DEASSERT_H;
				avl_read_req_2 <= `DEASSERT_H;
				
				wr_rdy2 <= `DEASSERT_H;
				rd_rdy2 <= `DEASSERT_H;
					
				if (avl_ready_2 == `ASSERT_H && wr_en2 == `ASSERT_L
							&& prev_wr_addr2 != wr_addr2
							&& rd_en2 == `DEASSERT_L) begin
					curr_state2 <= WRITE;
					wr_rdy2 <= `ASSERT_H;
				end else if (avl_ready_2 == `ASSERT_H && rd_en2 == `ASSERT_L 
									&& prev_rd_addr2 != rd_addr2
									&& wr_en2 == `DEASSERT_L) begin
					curr_state2 <= READ;
					rd_rdy2 <= `ASSERT_H;
				end else
					curr_state2 <= IDLE;
			end
			
			WRITE: begin
				wr_rdy2 <= `ASSERT_H;
				rd_rdy2 <= `DEASSERT_H;

				if (avl_ready_2 == `ASSERT_H && wr_en2 == `ASSERT_L
							 && rd_en2 == `DEASSERT_L) begin
					avl_write_req_2 <= `ASSERT_H;
					avl_addr_2 <= wr_addr2;
					prev_wr_addr2 <= avl_addr_2;
				end
				
				if (rd_en2 == `ASSERT_L || (rd_en2 == `ASSERT_L &&
							wr_en2 == `ASSERT_L)) begin
					curr_state2 <= READ;
					rd_rdy2 <= `ASSERT_H;
					wr_rdy2 <= `DEASSERT_H;
				end else if (wr_en2 == `ASSERT_L)
					curr_state2 <= WRITE;
				else
					curr_state2 <= IDLE;
			end
			
			READ: begin
				rd_rdy2 <= `ASSERT_H;
				wr_rdy2 <= `DEASSERT_H;

				if (avl_ready_2 == `ASSERT_H && rd_en2 == `ASSERT_L
							 && wr_en2 == `DEASSERT_L) begin
					avl_read_req_2 <= `ASSERT_H;
					avl_addr_2 <= rd_addr2;
					prev_rd_addr2 <= avl_addr_2;
				end
				
				if (wr_en2 == `ASSERT_L || (rd_en2 == `ASSERT_L &&
								wr_en2 == `ASSERT_L)) begin
					curr_state2 <= WRITE;
					wr_rdy2 <= `ASSERT_H;
					rd_rdy2 <= `DEASSERT_H;
				end else if (rd_en2 == `ASSERT_L)
					curr_state2 <= READ;
				else
					curr_state2 <= IDLE;
			end
							
			default:  curr_state2 <= IDLE;
		endcase
	end
	/* End port 2 interface logic */
	
	/* Begin port 3 interface logic */
	always @(posedge clk) begin
		if (reset == `ASSERT_L) begin
			curr_state3 <= IDLE;
			
			avl_burstbegin_3 <= `DEASSERT_H;
			avl_size_3 <= 3'h1;
			avl_read_req_3 <= `DEASSERT_H;
			avl_write_req_3 <= `DEASSERT_H;
			
			prev_rd_addr3 <= {ADDR_WIDTH{1'h0}};
			prev_wr_addr3 <= {ADDR_WIDTH{1'h0}};
			
			wr_rdy3 <= `DEASSERT_H;
			rd_rdy3 <= `DEASSERT_H;
		end else
		
		case (curr_state3)
			IDLE: begin
				avl_write_req_3 <= `DEASSERT_H;
				avl_read_req_3 <= `DEASSERT_H;
				
				wr_rdy3 <= `DEASSERT_H;
				rd_rdy3 <= `DEASSERT_H;
					
				if (avl_ready_3 == `ASSERT_H && wr_en3 == `ASSERT_L
							&& prev_wr_addr3 != wr_addr3
							&& rd_en3 == `DEASSERT_L) begin
					curr_state3 <= WRITE;
					wr_rdy3 <= `ASSERT_H;
				end else if (avl_ready_3 == `ASSERT_H && rd_en3 == `ASSERT_L 
									&& prev_rd_addr3 != rd_addr3
									&& wr_en3 == `DEASSERT_L) begin
					curr_state3 <= READ;
					rd_rdy3 <= `ASSERT_H;
				end else
					curr_state3 <= IDLE;
			end
			
			WRITE: begin
				wr_rdy3 <= `ASSERT_H;
				rd_rdy3 <= `DEASSERT_H;

				if (avl_ready_3 == `ASSERT_H && wr_en3 == `ASSERT_L
							 && rd_en3 == `DEASSERT_L) begin
					avl_write_req_3 <= `ASSERT_H;
					avl_addr_3 <= wr_addr3;
					prev_wr_addr3 <= avl_addr_3;
				end
				
				if (rd_en3 == `ASSERT_L || (rd_en3 == `ASSERT_L &&
							wr_en3 == `ASSERT_L)) begin
					curr_state3 <= READ;
					rd_rdy3 <= `ASSERT_H;
					wr_rdy3 <= `DEASSERT_H;
				end else if (wr_en3 == `ASSERT_L)
					curr_state3 <= WRITE;
				else
					curr_state3 <= IDLE;
			end
			
			READ: begin
				rd_rdy3 <= `ASSERT_H;
				wr_rdy3 <= `DEASSERT_H;

				if (avl_ready_3 == `ASSERT_H && rd_en3 == `ASSERT_L
							 && wr_en3 == `DEASSERT_L) begin
					avl_read_req_3 <= `ASSERT_H;
					avl_addr_3 <= rd_addr3;
					prev_rd_addr3 <= avl_addr_3;
				end
				
				if (wr_en3 == `ASSERT_L || (rd_en3 == `ASSERT_L &&
								wr_en3 == `ASSERT_L)) begin
					curr_state3 <= WRITE;
					wr_rdy3 <= `ASSERT_H;
					rd_rdy3 <= `DEASSERT_H;
				end else if (rd_en3 == `ASSERT_L)
					curr_state3 <= READ;
				else
					curr_state3 <= IDLE;
			end
							
			default:  curr_state3 <= IDLE;
		endcase
	end
	/* End port 3 interface logic */
	
	assign avl_be_0 = BE;
	assign avl_be_1 = BE;
	assign avl_be_2 = BE;
	assign avl_be_3 = BE;
	
	/* Begin IP instantiations */
	LPDDR2x32_4p lpddr2x32_4p_inst (
		.pll_ref_clk                (clk_50m),                                    //        pll_ref_clk.clk
		.global_reset_n             (global_reset_n),                                 //       global_reset.reset_n
		.soft_reset_n               (soft_reset_n),                                   //         soft_reset.reset_n
		.afi_clk                    (),                                               //            afi_clk.clk
		.afi_half_clk               (),                                               //       afi_half_clk.clk
		.afi_reset_n                (),                                               //          afi_reset.reset_n
		.afi_reset_export_n         (),                                               //   afi_reset_export.reset_n
		.mem_ca                     (mem_ca),                                         //             memory.mem_ca
		.mem_ck                     (mem_ck),                                         //                   .mem_ck
		.mem_ck_n                   (mem_ck_n),                                       //                   .mem_ck_n
		.mem_cke                    (mem_cke),                                        //                   .mem_cke
		.mem_cs_n                   (mem_cs_n),                                       //                   .mem_cs_n
		.mem_dm                     (mem_dm),                                         //                   .mem_dm
		.mem_dq                     (mem_dq),                                         //                   .mem_dq
		.mem_dqs                    (mem_dqs),                                        //                   .mem_dqs
		.mem_dqs_n                  (mem_dqs_n),                                      //                   .mem_dqs_n
		.avl_ready_0                (avl_ready_0),                                    //              avl_0.waitrequest_n
		.avl_burstbegin_0           (avl_burstbegin_0),                               //                   .beginbursttransfer
		.avl_addr_0                 (avl_addr_0),                                     //                   .address
		.avl_rdata_valid_0          (avl_rdata_valid_0),                              //                   .readdatavalid
		.avl_rdata_0                (rd_data0),                                       //                   .readdata
		.avl_wdata_0                (wr_data0),                                       //                   .writedata
		.avl_be_0                   (avl_be_0),                                       //                   .byteenable
		.avl_read_req_0             (avl_read_req_0),                                 //                   .read
		.avl_write_req_0            (avl_write_req_0),                                //                   .write
		.avl_size_0                 (avl_size_0),                                     //                   .burstcount
		.avl_ready_1                (avl_ready_1),                                    //              avl_1.waitrequest_n
		.avl_burstbegin_1           (avl_burstbegin_1),                               //                   .beginbursttransfer
		.avl_addr_1                 (avl_addr_1),                                     //                   .address
		.avl_rdata_valid_1          (avl_rdata_valid_1),                              //                   .readdatavalid
		.avl_rdata_1                (rd_data1),                                       //                   .readdata
		.avl_wdata_1                (wr_data1),                                       //                   .writedata
		.avl_be_1                   (avl_be_1),                                       //                   .byteenable
		.avl_read_req_1             (avl_read_req_1),                                 //                   .read
		.avl_write_req_1            (avl_write_req_1),                                //                   .write
		.avl_size_1                 (avl_size_1),                                     //                   .burstcount
		.avl_ready_2                (avl_ready_2),                                    //              avl_2.waitrequest_n
		.avl_burstbegin_2           (avl_burstbegin_2),                               //                   .beginbursttransfer
		.avl_addr_2                 (avl_addr_2),                                     //                   .address
		.avl_rdata_valid_2          (avl_rdata_valid_2),                              //                   .readdatavalid
		.avl_rdata_2                (rd_data2),                                       //                   .readdata
		.avl_wdata_2                (wr_data2),                                       //                   .writedata
		.avl_be_2                   (avl_be_2),                                       //                   .byteenable
		.avl_read_req_2             (avl_read_req_2),                                 //                   .read
		.avl_write_req_2            (avl_write_req_2),                                //                   .write
		.avl_size_2                 (avl_size_2),                                     //                   .burstcount
		.avl_ready_3                (avl_ready_3),                                    //              avl_3.waitrequest_n
		.avl_burstbegin_3           (avl_burstbegin_3),                               //                   .beginbursttransfer
		.avl_addr_3                 (avl_addr_3),                                     //                   .address
		.avl_rdata_valid_3          (avl_rdata_valid_3),                              //                   .readdatavalid
		.avl_rdata_3                (rd_data3),                                       //                   .readdata
		.avl_wdata_3                (wr_data3),                                       //                   .writedata
		.avl_be_3                   (avl_be_3),                                       //                   .byteenable
		.avl_read_req_3             (avl_read_req_3),                                 //                   .read
		.avl_write_req_3            (avl_write_req_3),                                //                   .write
		.avl_size_3                 (avl_size_3),                                     //                   .burstcount
		.mp_cmd_clk_0_clk           (clk),                              //       mp_cmd_clk_0.clk
		.mp_cmd_reset_n_0_reset_n   (~rst_controller_reset_out_reset),                //   mp_cmd_reset_n_0.reset_n
		.mp_cmd_clk_1_clk           (clk),                              //       mp_cmd_clk_1.clk
		.mp_cmd_reset_n_1_reset_n   (~rst_controller_001_reset_out_reset),            //   mp_cmd_reset_n_1.reset_n
		.mp_cmd_clk_2_clk           (clk),                              //       mp_cmd_clk_2.clk
		.mp_cmd_reset_n_2_reset_n   (~rst_controller_002_reset_out_reset),            //   mp_cmd_reset_n_2.reset_n
		.mp_cmd_clk_3_clk           (clk),                              //       mp_cmd_clk_3.clk
		.mp_cmd_reset_n_3_reset_n   (~rst_controller_003_reset_out_reset),            //   mp_cmd_reset_n_3.reset_n
		.mp_rfifo_clk_0_clk         (clk),                              //     mp_rfifo_clk_0.clk
		.mp_rfifo_reset_n_0_reset_n (~rst_controller_004_reset_out_reset),            // mp_rfifo_reset_n_0.reset_n
		.mp_wfifo_clk_0_clk         (clk),                              //     mp_wfifo_clk_0.clk
		.mp_wfifo_reset_n_0_reset_n (~rst_controller_005_reset_out_reset),            // mp_wfifo_reset_n_0.reset_n
		.mp_rfifo_clk_1_clk         (clk),                              //     mp_rfifo_clk_1.clk
		.mp_rfifo_reset_n_1_reset_n (~rst_controller_006_reset_out_reset),            // mp_rfifo_reset_n_1.reset_n
		.mp_wfifo_clk_1_clk         (clk),                              //     mp_wfifo_clk_1.clk
		.mp_wfifo_reset_n_1_reset_n (~rst_controller_007_reset_out_reset),            // mp_wfifo_reset_n_1.reset_n
		.mp_rfifo_clk_2_clk         (clk),                              //     mp_rfifo_clk_2.clk
		.mp_rfifo_reset_n_2_reset_n (~rst_controller_008_reset_out_reset),            // mp_rfifo_reset_n_2.reset_n
		.mp_wfifo_clk_2_clk         (clk),                              //     mp_wfifo_clk_2.clk
		.mp_wfifo_reset_n_2_reset_n (~rst_controller_009_reset_out_reset),            // mp_wfifo_reset_n_2.reset_n
		.mp_rfifo_clk_3_clk         (clk),                              //     mp_rfifo_clk_3.clk
		.mp_rfifo_reset_n_3_reset_n (~rst_controller_010_reset_out_reset),            // mp_rfifo_reset_n_3.reset_n
		.mp_wfifo_clk_3_clk         (clk),                              //     mp_wfifo_clk_3.clk
		.mp_wfifo_reset_n_3_reset_n (~rst_controller_011_reset_out_reset),            // mp_wfifo_reset_n_3.reset_n
		.local_init_done            (local_init_done),                                //             status.local_init_done
		.local_cal_success          (local_cal_success),                              //                   .local_cal_success
		.local_cal_fail             (local_cal_fail),                                 //                   .local_cal_fail
		.oct_rzqin                  (oct_rzqin),                                      //                oct.rzqin
		.pll_mem_clk                (),                                               //        pll_sharing.pll_mem_clk
		.pll_write_clk              (),                                               //                   .pll_write_clk
		.pll_locked                 (pll_locked_ddr),                                 //                   .pll_locked
		.pll_write_clk_pre_phy_clk  (),                                               //                   .pll_write_clk_pre_phy_clk
		.pll_addr_cmd_clk           (),                                               //                   .pll_addr_cmd_clk
		.pll_avl_clk                (),                                               //                   .pll_avl_clk
		.pll_config_clk             (),                                               //                   .pll_config_clk
		.pll_mem_phy_clk            (),                                               //                   .pll_mem_phy_clk
		.afi_phy_clk                (),                                               //                   .afi_phy_clk
		.pll_avl_phy_clk            (),                                               //                   .pll_avl_phy_clk
		.seq_debug_addr             (),                                               //          seq_debug.address
		.seq_debug_read_req         (),                                               //                   .read
		.seq_debug_rdata            (),                                               //                   .readdata
		.seq_debug_write_req        (),                                               //                   .write
		.seq_debug_wdata            (),                                               //                   .writedata
		.seq_debug_waitrequest      (),                                               //                   .waitrequest
		.seq_debug_be               (),                                               //                   .byteenable
		.seq_debug_rdata_valid      ()                                                //                   .readdatavalid
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                               //       clk.clk
		.reset_out      (rst_controller_reset_out_reset), // reset_out.reset
		.reset_req      (),                               // (terminated)
		.reset_req_in0  (1'b0),                           // (terminated)
		.reset_req_in1  (1'b0),                           // (terminated)
		.reset_req_in2  (1'b0),                           // (terminated)
		.reset_in3      (1'b0),                           // (terminated)
		.reset_req_in3  (1'b0),                           // (terminated)
		.reset_in4      (1'b0),                           // (terminated)
		.reset_req_in4  (1'b0),                           // (terminated)
		.reset_in5      (1'b0),                           // (terminated)
		.reset_req_in5  (1'b0),                           // (terminated)
		.reset_in6      (1'b0),                           // (terminated)
		.reset_req_in6  (1'b0),                           // (terminated)
		.reset_in7      (1'b0),                           // (terminated)
		.reset_req_in7  (1'b0),                           // (terminated)
		.reset_in8      (1'b0),                           // (terminated)
		.reset_req_in8  (1'b0),                           // (terminated)
		.reset_in9      (1'b0),                           // (terminated)
		.reset_req_in9  (1'b0),                           // (terminated)
		.reset_in10     (1'b0),                           // (terminated)
		.reset_req_in10 (1'b0),                           // (terminated)
		.reset_in11     (1'b0),                           // (terminated)
		.reset_req_in11 (1'b0),                           // (terminated)
		.reset_in12     (1'b0),                           // (terminated)
		.reset_req_in12 (1'b0),                           // (terminated)
		.reset_in13     (1'b0),                           // (terminated)
		.reset_req_in13 (1'b0),                           // (terminated)
		.reset_in14     (1'b0),                           // (terminated)
		.reset_req_in14 (1'b0),                           // (terminated)
		.reset_in15     (1'b0),                           // (terminated)
		.reset_req_in15 (1'b0)                            // (terminated)
	);

	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_001 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_001_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);

	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_002 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_002_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_003 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_003_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_004 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_004_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_005 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_005_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_006 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_006_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_007 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_007_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_008 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_008_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_009 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_009_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_010 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_010_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);
	
	altera_reset_controller #(
		.NUM_RESET_INPUTS          (2),
		.OUTPUT_RESET_SYNC_EDGES   ("none"),
		.SYNC_DEPTH                (2),
		.RESET_REQUEST_PRESENT     (0),
		.RESET_REQ_WAIT_TIME       (1),
		.MIN_RST_ASSERTION_TIME    (3),
		.RESET_REQ_EARLY_DSRT_TIME (1),
		.USE_RESET_REQUEST_IN0     (0),
		.USE_RESET_REQUEST_IN1     (0),
		.USE_RESET_REQUEST_IN2     (0),
		.USE_RESET_REQUEST_IN3     (0),
		.USE_RESET_REQUEST_IN4     (0),
		.USE_RESET_REQUEST_IN5     (0),
		.USE_RESET_REQUEST_IN6     (0),
		.USE_RESET_REQUEST_IN7     (0),
		.USE_RESET_REQUEST_IN8     (0),
		.USE_RESET_REQUEST_IN9     (0),
		.USE_RESET_REQUEST_IN10    (0),
		.USE_RESET_REQUEST_IN11    (0),
		.USE_RESET_REQUEST_IN12    (0),
		.USE_RESET_REQUEST_IN13    (0),
		.USE_RESET_REQUEST_IN14    (0),
		.USE_RESET_REQUEST_IN15    (0),
		.ADAPT_RESET_REQUEST       (0)
	) rst_controller_011 (
		.reset_in0      (~global_reset_n),          // reset_in0.reset
		.reset_in1      (~soft_reset_n),                // reset_in1.reset
		.clk            (),                                   //       clk.clk
		.reset_out      (rst_controller_011_reset_out_reset), // reset_out.reset
		.reset_req      (),                                   // (terminated)
		.reset_req_in0  (1'b0),                               // (terminated)
		.reset_req_in1  (1'b0),                               // (terminated)
		.reset_req_in2  (1'b0),                               // (terminated)
		.reset_in3      (1'b0),                               // (terminated)
		.reset_req_in3  (1'b0),                               // (terminated)
		.reset_in4      (1'b0),                               // (terminated)
		.reset_req_in4  (1'b0),                               // (terminated)
		.reset_in5      (1'b0),                               // (terminated)
		.reset_req_in5  (1'b0),                               // (terminated)
		.reset_in6      (1'b0),                               // (terminated)
		.reset_req_in6  (1'b0),                               // (terminated)
		.reset_in7      (1'b0),                               // (terminated)
		.reset_req_in7  (1'b0),                               // (terminated)
		.reset_in8      (1'b0),                               // (terminated)
		.reset_req_in8  (1'b0),                               // (terminated)
		.reset_in9      (1'b0),                               // (terminated)
		.reset_req_in9  (1'b0),                               // (terminated)
		.reset_in10     (1'b0),                               // (terminated)
		.reset_req_in10 (1'b0),                               // (terminated)
		.reset_in11     (1'b0),                               // (terminated)
		.reset_req_in11 (1'b0),                               // (terminated)
		.reset_in12     (1'b0),                               // (terminated)
		.reset_req_in12 (1'b0),                               // (terminated)
		.reset_in13     (1'b0),                               // (terminated)
		.reset_req_in13 (1'b0),                               // (terminated)
		.reset_in14     (1'b0),                               // (terminated)
		.reset_req_in14 (1'b0),                               // (terminated)
		.reset_in15     (1'b0),                               // (terminated)
		.reset_req_in15 (1'b0)                                // (terminated)
	);

endmodule