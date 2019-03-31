
// RGB blink example

`ifdef EVT
`define BLUEPWM  RGB0PWM
`define REDPWM   RGB1PWM
`define GREENPWM RGB2PWM
`else
`define BLUEPWM  RGB0PWM
`define GREENPWM RGB1PWM
`define REDPWM   RGB2PWM
`endif

module rgbblink (
    output rgb0,       // SB_RGBA_DRV external pins
    output rgb1,
    output rgb2,
    input clki         // Clock
);

    // Connect to system clock (with buffering)
    wire clkosc;
    SB_GB clk_gb (
        .USER_SIGNAL_TO_GLOBAL_BUFFER(clki),
        .GLOBAL_BUFFER_OUTPUT(clkosc)
    );

    assign clk = clkosc;

    reg [23:0] slowdowncounter;
    reg [7:0] pwmcounter;
    reg [7:0] pulse;
    reg [2:0] RGBcounter;

    wire enable_blue;
    wire enable_green;
    wire enable_red;

    always @(posedge clk) begin
		slowdowncounter <= slowdowncounter + 1;
		pwmcounter <= pwmcounter + 1;
		if (slowdowncounter == 600000) begin
			slowdowncounter <= 0;
			pulse <= pulse + 1;
		end
		if (pulse == 0) begin
			RGBcounter <= RGBcounter + 1;
		end

		if (pwmcounter<pulse) begin
			enable_red <= RGBcounter[0];
			enable_green <= RGBcounter[1];
			enable_blue <= RGBcounter[2];
		end else begin
			enable_red <= 0;
			enable_green <= 0;
			enable_blue <= 0;
		end
	end
 

    // Instantiate iCE40 LED driver hard logic, connecting up
    // latched button state, counter state, and LEDs.
    //
    SB_RGBA_DRV RGBA_DRIVER (
        .CURREN(1'b1),
        .RGBLEDEN(1'b1),
        .`BLUEPWM(enable_blue),   // Blue
        .`REDPWM(enable_red),     // Red
        .`GREENPWM(enable_green),    // Green (blinking)
        .RGB0(rgb0),
        .RGB1(rgb1),
        .RGB2(rgb2)
    );

    // Parameters from iCE40 UltraPlus LED Driver Usage Guide, pages 19-20
    //
    // https://www.latticesemi.com/-/media/LatticeSemi/Documents/ApplicationNotes/IK/ICE40LEDDriverUsageGuide.ashx?document_id=50668
    //
    localparam RGBA_CURRENT_MODE_FULL = "0b0";
    localparam RGBA_CURRENT_MODE_HALF = "0b1";

    // Current levels in Full / Half mode
    localparam RGBA_CURRENT_04MA_02MA = "0b000001";
    localparam RGBA_CURRENT_08MA_04MA = "0b000011";
    localparam RGBA_CURRENT_12MA_06MA = "0b000111";
    localparam RGBA_CURRENT_16MA_08MA = "0b001111";
    localparam RGBA_CURRENT_20MA_10MA = "0b011111";
    localparam RGBA_CURRENT_24MA_12MA = "0b111111";

    // Set parameters of RGBA_DRIVER (output current)
    //
    // Mapping of RGBn to LED colours determined experimentally
    //
    defparam RGBA_DRIVER.CURRENT_MODE = RGBA_CURRENT_MODE_FULL;
    defparam RGBA_DRIVER.RGB0_CURRENT = RGBA_CURRENT_08MA_04MA;  // Blue
    defparam RGBA_DRIVER.RGB1_CURRENT = RGBA_CURRENT_04MA_02MA;  // Red
    defparam RGBA_DRIVER.RGB2_CURRENT = RGBA_CURRENT_04MA_02MA;  // Green

endmodule
