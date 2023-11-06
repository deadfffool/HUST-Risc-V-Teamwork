`timescale 1ns / 1ps

module vga_display (
           input clk ,  //65MHz 
           input [11: 0] vdata ,
           
           output [10:0] vaddr_x,
           output [10:0] vaddr_y,
           
           output h_sync, v_sync,
           output reg [11: 0] vga  
       );

wire [11: 0] x_counter;
wire [10: 0] y_counter;
wire in_display_area;

// function of this module:
// x_counter and y_counter range from 0 to (h/v)_total_piexls-1,
// just assignment vga to appropriate value according to x_counter and y_counter
// Notice: "scanning" occers here, which means x_counter and y_counter are increasing
vga_sync_generator vga_sync_generator(
        .clk(clk),
        .x_counter(x_counter),
        .y_counter(y_counter),
        .h_sync(h_sync),
        .v_sync(v_sync),
        .in_display_area(in_display_area)
    );

assign vaddr_x = (in_display_area) ? x_counter:0;
assign vaddr_y = (in_display_area) ? y_counter:0;


always @(posedge clk)
  begin
    if (in_display_area)
      begin
        vga <= vdata;
      end
    else vga <= 12'h000;
  end
 
endmodule

module vga_sync_generator (
           input clk ,
           output reg [11: 0] x_counter ,
           output reg [10: 0] y_counter ,
           output reg h_sync, v_sync ,
           output reg in_display_area
        );

//localparam h_active_pixels = 1920 ;
//localparam h_front_porch = 88 ;
//localparam h_sync_width = 44 ;
//localparam h_back_porch = 148 ;
localparam h_active_pixels = 1024 ;
localparam h_front_porch = 24 ;
localparam h_sync_width = 136 ;
localparam h_back_porch = 160 ;
localparam h_total_piexls = (h_active_pixels + h_front_porch + h_back_porch + h_sync_width);

//localparam v_active_pixels = 1080 ;
//localparam v_front_porch = 4 ;
//localparam v_sync_width = 5 ;
//localparam v_back_porch = 36 ;
localparam v_active_pixels = 768 ;
localparam v_front_porch = 3 ;
localparam v_sync_width = 6 ;
localparam v_back_porch = 29 ;
localparam v_total_piexls = (v_active_pixels + v_front_porch + v_back_porch + v_sync_width);


initial begin
    x_counter=0;
    y_counter=0;
end

always @(posedge clk)

    if (x_counter == h_total_piexls-1)
        x_counter <= 0;
    else
        x_counter <= x_counter + 1;


always @(posedge clk)
    if (x_counter == h_total_piexls-1)
    begin
        if (y_counter == v_total_piexls-1)
            y_counter <= 0;
        else
            y_counter <= y_counter + 1;
    end

always @(posedge clk)
begin
    h_sync <= !(x_counter >= h_active_pixels + h_front_porch && x_counter < h_active_pixels + h_front_porch + h_sync_width);
    v_sync <= !(y_counter >= v_active_pixels + v_front_porch && y_counter < v_active_pixels + v_front_porch + v_sync_width);
end

always @(posedge clk)
begin
    in_display_area <= (x_counter < h_active_pixels) && (y_counter < v_active_pixels);
end

endmodule

module vga_graph_mode(
           input clk,
           // provider
           input [10: 0] vaddr_x,
           input [10: 0] vaddr_y,
           output [11: 0] vga_graph_mode_output,

           // modifier
           input pixel_modify_enable,
           input [10: 0] pixel_addr_x_to_change,
           input [10: 0] pixel_addr_y_to_change,
           input [11: 0] pixel_newRGB
       );

reg [11:0] ram [12288-1:0];

initial begin
        $readmemh("C:\\Users\\Miles\\Desktop\\HUST-Risc-V-Teamwork\\rgb_data.txt",ram);
end

wire [20: 0] vaddr;
wire [7: 0] mem_x=vaddr_x/8;
wire [7: 0] mem_y=vaddr_y/8;
wire  [20: 0] pixel_addr_to_change;

assign vaddr=mem_y*128 + mem_x;
assign vga_graph_mode_output = ram[vaddr]; 

assign pixel_addr_to_change = pixel_addr_y_to_change*128 + pixel_addr_x_to_change;
  
always @(posedge clk) begin 
    if(pixel_modify_enable)
        ram[pixel_addr_to_change]<=pixel_newRGB;
end

endmodule


