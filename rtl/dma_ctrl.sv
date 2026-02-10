typedef enum logic [2:0] {
    IDLE,
    READ,
    WRITE,
    COMPLETE,
    ERROR
} dma_state_e;

module dma_ctrl #(
    parameter int BURST_SIZE = 16, // In Bytes
    parameter int ADDR_WIDTH = 32
)(
//Control inputs
input logic                     clk,
input logic                     rst_n,
input logic                     start_pulse,
input logic                     done_clear,
input logic                     error_clear,
input logic [ADDR_WIDTH-1:0]    src_addr,
input logic [ADDR_WIDTH-1:0]    dst_addr,
input logic [31:0]              length,

// Handshake feedback
input logic                     fifo_full,
input logic                     fifo_empty,
input logic                     read_done,
input logic                     write_done,
input logic                     read_error,
input logic                     write_error,

//Control outputs
output logic                    read_enable,
output logic                    write_enable,
output logic [ADDR_WIDTH-1:0]   current_src_addr,
output logic [ADDR_WIDTH-1:0]   current_dst_addr,
output logic [31:0]             current_burst_len,

//Status
output logic                    busy,
output logic                    done,
output logic                    error
);
    // FSMs are always split in 3 logical blocks:
    // ------------------------------------------------------------------------
    // 1. FSM State Register
    // ------------------------------------------------------------------------
    dma_state_e current_state, next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // ------------------------------------------------------------------------
    // 2. FSM Next-State Logic
    // ------------------------------------------------------------------------
    always_comb begin
        next_state = current_state;

        unique case (current_state)
            IDLE:
                // Wait for start_pulse from APB control logic
                if (start_pulse)
                    next_state = READ;

            READ:
                // If AXI error occurred during read, bail to ERROR
                if (read_error)
                    next_state = ERROR;
                // Otherwise move to WRITE once read burst completes
                else if (read_done)
                    next_state = WRITE;

            WRITE:
                if (write_error)
                    next_state = ERROR;
                // If transfer is fully complete, signal done
                else if (write_done && bytes_left == 0)
                    next_state = COMPLETE;
                // Otherwise go back to next read burst
                else if (write_done)
                    next_state = READ;

            COMPLETE:
                // Wait until software clears DONE flag
                if (done_clear)
                    next_state = IDLE;

            ERROR:
                // Wait until software clears ERROR flag
                if (error_clear)
                    next_state = IDLE;

            default:
                next_state = IDLE;
        endcase
    end

    // ------------------------------------------------------------------------
    // 3. Output / Control Logic (based on FSM state)
    // ------------------------------------------------------------------------
    always_comb begin
        // Default outputs
        read_enable   = 0;
        write_enable  = 0;
        done          = 0;
        error         = 0;
        busy          = (current_state != IDLE);  // Transfer is active in any non-IDLE state

        unique case (current_state)
            READ:    read_enable  = 1;
            WRITE:   write_enable = 1;
            COMPLETE: done        = 1;
            ERROR:    error       = 1;
        endcase
    end

    // ------------------------------------------------------------------------
    // Address Pointer and Byte Counter Register Logic
    // ------------------------------------------------------------------------

    logic [ADDR_WIDTH-1:0] src_ptr, dst_ptr;
    logic [31:0]           bytes_left;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            src_ptr    <= '0;
            dst_ptr    <= '0;
            bytes_left <= '0;
        end else if (start_pulse) begin
            // Latch initial config values on START
            src_ptr    <= src_addr;
            dst_ptr    <= dst_addr;
            bytes_left <= length;
        end else if (write_done) begin
            // Update internal pointers after each write burst
            src_ptr    <= src_ptr + current_burst_len;
            dst_ptr    <= dst_ptr + current_burst_len;
            bytes_left <= bytes_left - current_burst_len;
        end
    end

    // ------------------------------------------------------------------------
    // Burst Size Logic
    // ------------------------------------------------------------------------
    // Select the number of bytes to read/write next.
    // Final burst may be smaller than BURST_SIZE if nearing end of transfer.

    assign current_src_addr    = src_ptr;
    assign current_dst_addr    = dst_ptr;
    assign current_burst_len   = (bytes_left >= BURST_SIZE) ? BURST_SIZE : bytes_left;

endmodule
