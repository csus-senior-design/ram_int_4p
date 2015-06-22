	component ISSP is
		port (
			probe      : in  std_logic_vector(68 downto 0) := (others => 'X'); -- probe
			source_clk : in  std_logic                     := 'X';             -- clk
			source     : out std_logic_vector(92 downto 0)                     -- source
		);
	end component ISSP;

	u0 : component ISSP
		port map (
			probe      => CONNECTED_TO_probe,      --     probes.probe
			source_clk => CONNECTED_TO_source_clk, -- source_clk.clk
			source     => CONNECTED_TO_source      --    sources.source
		);

