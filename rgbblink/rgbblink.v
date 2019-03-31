// Simple tri-colour LED blink example, with button control
//
// Green LED blinks forever.  Blue LED turned on when Button 5 is pressed.
// Red LED turned on when Button 6 is pressed.
//
// LOG2DELAY controls the division of the module clock to the bit interval
// (by requiring count to 2 ** LOG2DELAY before changing LED state bits)
//
// On EVT Fomu boards:
//
// 1st LED colour - Blue  - controlled by pressing Button 5, or connect 1 to 2
// 2nd LED colour - Red   - controlled by pressing Button 6, or connect 3 to 4
// 3rd LED colour - Green - controlled by clock (blinking)
//
// On DVT / Hacker / Production Fomu boards:
//
// 1st LED colour - Blue  - turn on by connecting pin 1 to pin 2
// 2nd LED colour - Green - controlled by clock (blinking)
// 3rd LED colour - Red   - turn on by connecting pin 3 to pin 4
//
// We use `defines to handle these two cases, because the SB_RGBA_DRV
// iCE40UP5K hard macro is unable to do RGBn to output pin mapping internally
// (the RGB0 / RGB1 / RGB2 parameters to SB_RGBA_DRV *must* be mapped
// to the same named RGB0 / RGB1 / RGB2 physical pins; arachne-pnr
// errors if they are not, and currently nextpnr just ignores mismapped
// pins and enforces this mapping)
//
// This is all kludged into a single file to make a standalone simple test;
// a better design would wrap SB_RGBA_DRV into a Fomu specific module and
// hide the LED colour mapping; and also set the appropriate pins for
// the buttons at instantiation time.
//
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
