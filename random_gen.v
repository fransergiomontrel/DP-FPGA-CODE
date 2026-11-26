module random_16bit (
    input  wire        clk,
    input  wire        reset,
    input  wire        enable,
    output wire [15:0] random_out
);

    reg [17:0] lfsr;

    wire feedback;

    assign feedback = lfsr[17] ^ lfsr[10];

    assign random_out = lfsr[15:0];

    always @(posedge clk or posedge reset) begin
        if (reset)
            lfsr <= 18'h2ACE1;
        else if (enable)
            lfsr <= {lfsr[16:0], feedback};
    end

endmodule