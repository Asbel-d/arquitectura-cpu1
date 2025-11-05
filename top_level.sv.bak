module top_level(
  input wire clk,
  input wire rst_n,
  output wire [6:0] display,
  output wire [9:0] leds
);

  logic [31:0] pc;

  // This block will change when you implement branching.
  always @(posedge clk) begin
    if (!rst_n)
      pc <= 32'b0;
    else
      pc <= pc + 4;
  end


  hex7seg display0(
    .val(pc[3:0]),
    .display(display)
  );

  assign leds = 10'b1010101010;
endmodule 
