// ISSP.v

// Generated using ACDS version 14.1 186 at 2015.03.30.18:16:18

`timescale 1 ps / 1 ps
module ISSP (
		input  wire [68:0] probe,      //     probes.probe
		input  wire        source_clk, // source_clk.clk
		output wire [92:0] source      //    sources.source
	);

	altsource_probe #(
		.sld_auto_instance_index ("YES"),
		.sld_instance_index      (0),
		.instance_id             ("NONE"),
		.probe_width             (69),
		.source_width            (93),
		.source_initial_value    ("7"),
		.enable_metastability    ("YES")
	) in_system_sources_probes_0 (
		.source     (source),     //    sources.source
		.source_clk (source_clk), // source_clk.clk
		.probe      (probe)       //     probes.probe
	);

endmodule
