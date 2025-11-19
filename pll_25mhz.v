module pll_25mhz (
    input  wire clk50,
    output wire clk25
);

    altera_pll #(
        .reference_clock_frequency("50.0 MHz"),
        .operation_mode("direct"),
        .number_of_clocks(1),
        .output_clock_frequency0("25.000000 MHz")
    ) pll_inst (
        .refclk(clk50),
        .rst(1'b0),
        .outclk({clk25}),
        .locked()
    );

endmodule
