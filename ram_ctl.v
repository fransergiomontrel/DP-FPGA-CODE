module ram_ctl_module #(
    parameter N_CELLS = 262144
)(
    input  wire clk,
    input  wire reset,
    input  wire [15:0] data_from_ram_in,
    output wire we_n_out,
    output wire oe_n_out,
    output wire cs_n_out,
    output wire addr_inc_read_out,
    output wire addr_inc_write_out,
    output wire write_enable_out,
    output wire data_bus_out,
    output wire addr_clr_out,
    output reg  [15:0] data_to_ram_out
);

    // Registers
    reg we_n_reg;
    reg oe_n_reg;
    reg cs_n_reg;
    reg write_enable_reg;
    reg data_bus_reg;
    reg addr_inc_read_reg;
    reg addr_inc_write_reg;
    reg addr_clr_reg;
    reg en_new_random;
    reg [15:0] read_data;
    reg [2:0] delay;
    reg [17:0] count_cells;

    // Connection between registers and output signals
    assign we_n_out = we_n_reg;
    assign oe_n_out = oe_n_reg;
    assign cs_n_out = cs_n_reg;
    assign addr_inc_read_out = addr_inc_read_reg;
    assign addr_inc_write_out = addr_inc_write_reg;
    assign write_enable_out = write_enable_reg;
    assign data_bus_out = data_bus_reg;
    assign addr_clr_out = addr_clr_reg;

    // Definicao dos estados
    localparam START_CHECK = 4'b0000;
    localparam NEW_RANDOM  = 4'b0001;
    localparam START_WRITE = 4'b0010;
	 localparam AWAIT_WRITE = 4'b0011;
    localparam AWAIT_READ  = 4'b0100;
    localparam CHECK_CELL  = 4'b0101;
    localparam IDLE        = 4'b0110;
    

    reg [3:0] ram_ctl_state;

    wire [15:0] random_bus;

    random_16bit u_random_16bit (
        .clk(clk),
        .reset(reset),
        .enable(en_new_random),
        .random_out(random_bus)
    );

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            we_n_reg <= 1'b1;
            oe_n_reg <= 1'b1;
            cs_n_reg <= 1'b1;
            write_enable_reg <= 1'b1;
            data_bus_reg <= 1'b1;
            addr_inc_read_reg <= 1'b0;
            addr_inc_write_reg <= 1'b0;
            addr_clr_reg <= 1'b0;
            en_new_random <= 1'b0;
            data_to_ram_out <= 16'h0000;
            delay <= 3'd0;
            count_cells <= 18'd0;
            ram_ctl_state <= START_CHECK;

        end
        else begin

            case (ram_ctl_state)

                START_CHECK:
                begin

                    en_new_random <= 1'b1;
                    ram_ctl_state <= NEW_RANDOM;

                end

                NEW_RANDOM:
                begin

                    addr_inc_read_reg <= 1'b0;
                    addr_inc_write_reg <= 1'b0;
                    cs_n_reg <= 1'b0;
                    en_new_random <= 1'b0;
                    ram_ctl_state <= START_WRITE;

                end

                START_WRITE:
                begin

                    we_n_reg <= 1'b0;
                    data_to_ram_out <= random_bus;
                    ram_ctl_state <= AWAIT_WRITE;

                end

                AWAIT_WRITE:
                begin

                    delay <= delay + 3'd1;

                    // Await write time
                    if (delay == 3'd2) begin

                        delay <= 3'd0;
                        data_bus_reg <= 1'b0;
                        write_enable_reg <= 1'b0;
                        we_n_reg <= 1'b1;
                        oe_n_reg <= 1'b0;
                        ram_ctl_state <= AWAIT_READ;

                    end

                end

                AWAIT_READ:
                begin

                    delay <= delay + 3'd1;

                    // Await read time
                    if (delay == 3'd2) begin

                        read_data <= data_from_ram_in;
                        delay <= 3'd0;
                        ram_ctl_state <= CHECK_CELL;

                    end

                end

                CHECK_CELL:
                begin

                    if (count_cells < (N_CELLS - 1)) begin

                        oe_n_reg <= 1'b1;
                        en_new_random <= 1'b1;
                        addr_inc_read_reg <= 1'b1;
                        addr_inc_write_reg <= 1'b1;
                        count_cells <= count_cells + 18'd1;
                        ram_ctl_state <= NEW_RANDOM;

                        if (read_data == random_bus) begin

                            // Cell OK

                        end
                        else begin

                            // Cell error

                        end

                    end
                    else if (count_cells == (N_CELLS - 1)) begin

                        count_cells <= 18'd0;
								addr_clr_reg <= 1'b1;
                        ram_ctl_state <= IDLE;

                    end
                    else begin

                    end

                end

                IDLE:
                begin
				        addr_clr_reg <= 1'b0;
                end

            endcase

        end

    end

endmodule