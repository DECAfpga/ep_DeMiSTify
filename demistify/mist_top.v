`default_nettype none
//-------------------------------------------------------------------------------------------------
//  Elan Enterprise neptUNO board adapter
//-------------------------------------------------------------------------------------------------
//  This file is part of the Elan Enterprise FPGA implementation project.
//  Copyright (C) 2023 Kyp069 <kyp069@gmail.com>
//
//  This program is free software; you can redistribute it and/or modify it under the terms 
//  of the GNU General Public License as published by the Free Software Foundation;
//  either version 3 of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
//  without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License along with this program;
//  if not, If not, see <https://www.gnu.org/licenses/>.
//-------------------------------------------------------------------------------------------------
module mist_top
//-------------------------------------------------------------------------------------------------
(
	input         CLOCK_27,
	output        LED,

	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,

	input         SPI_SCK,
	inout         SPI_DO,
	input         SPI_DI,
	input         SPI_SS2,
	input         SPI_SS3,
	input         SPI_SS4,
	input         CONF_DATA0,

	input		  EAR,

	output        AUDIO_L,
	output        AUDIO_R,
	
	`ifdef DEMISTIFY
    output [15:0] DAC_L,
    output [15:0] DAC_R,

	input  [7:0]  joy1,
	input  [7:0]  joy2,

	inout         ps2mDQ,
	inout         ps2mCk,
    `endif

	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE

);
//-------------------------------------------------------------------------------------------------

wire[ 1:0] sync;
wire[17:0] rgb;

wire[ 1:0] dramDQM;

wire[ 1:0] dsg;

//-------------------------------------------------------------------------------------------------

localparam confStr =
{
	"Enterprise;;",
	"O24,Available RAM,1 MB,2 MB,3 MB,64 KB,128 KB,256 KB,512 KB;",
	"O5,CPU Speed,4 MHz,8 MHz;",
	"F,ROM,Load ROM;",
	"S0,IMGDSK,Mount A:;",
	"S1,VHD,Mount SD;",
	"V,V1.0;"
};

wire[ 1:0] sdRd;
wire[ 1:0] sdWr;
wire       sdAck;
wire[31:0] sdLba = sdBusy ? sdLba1 : sdLba0;
wire       sdBusy;
wire       sdConf;
wire       sdSdhc;
wire       sdAckCf;
wire[ 8:0] sdBuffA;
wire[ 7:0] sdBuffD = sdBusy ? sdBuffD1 : sdBuffD0;
wire[ 7:0] sdBuffQ;
wire       sdBuffW;
wire[ 1:0] imgMntd;
wire[63:0] imgSize;
wire[ 1:0] ps2ko;
wire[63:0] status;
wire       vga;

user_io #(.STRLEN(154), .SD_IMAGES(2)) user_io
(
	.conf_str        (confStr),
	.conf_addr       (       ),
	.conf_chr        (8'd0   ),
	.clk_sys         (clock32),
	.clk_sd          (clock32),
	.SPI_CLK         (SPI_SCK),
	.SPI_SS_IO       (CONF_DATA0),
	.SPI_MOSI        (SPI_DI ),
	.SPI_MISO        (SPI_DO ),
	.ps2_kbd_clk     (ps2ko[0]),
	.ps2_kbd_data    (ps2ko[1]),
	.ps2_kbd_clk_i   (1'b0),
	.ps2_kbd_data_i  (1'b0),
	.ps2_mouse_clk   (),
	.ps2_mouse_data  (),
	.ps2_mouse_clk_i (1'b0),
	.ps2_mouse_data_i(1'b0),
	.sd_rd           (sdRd   ),
	.sd_wr           (sdWr   ),
	.sd_ack          (sdAck  ),
	.sd_ack_conf     (sdAckCf),
	.sd_ack_x        (),
	.sd_lba          (sdLba  ),
    .sd_conf         (sdConf ),
	.sd_sdhc         (sdSdhc ),
	.sd_buff_addr    (sdBuffA),
	.sd_din          (sdBuffD),
	.sd_din_strobe   (),
	.sd_dout         (sdBuffQ),
	.sd_dout_strobe  (sdBuffW),
	.img_mounted     (imgMntd),
	.img_size        (imgSize),
	.rtc             (),
	.ypbpr           (),
	.status          (status),
	.buttons         (),
	.switches        (),
	.no_csync        (),
	.core_mod        (),
	.key_pressed     (),
	.key_extended    (),
	.key_code        (),
	.key_strobe      (),
	.kbd_out_data    (8'd0),
	.kbd_out_strobe  (1'b0),
	.mouse_x         (),
	.mouse_y         (),
	.mouse_z         (),
	.mouse_flags     (),
	.mouse_strobe    (),
	.mouse_idx       (),
	.joystick_0      (),
	.joystick_1      (),
	.joystick_2      (),
	.joystick_3      (),
	.joystick_4      (),
	.serial_data     (8'd0),
	.serial_strobe   (1'd0),
	.joystick_analog_0(),
	.joystick_analog_1(),
	.scandoubler_disable(vga)
);

wire       romIo;
wire[24:0] romA;
wire[ 7:0] romD;
wire       romW;

data_io	data_io
(
	.clk_sys       (clock32),
	.SPI_SCK       (SPI_SCK  ),
	.SPI_SS2       (SPI_SS2 ),
	.SPI_SS4       (SPI_SS4 ),
	.SPI_DI        (SPI_DI),
	.SPI_DO        (SPI_DO),
	.clkref_n      (1'b0   ),
	.ioctl_download(romIo  ),
	.ioctl_addr    (romA   ),
	.ioctl_din     (8'd0   ),
	.ioctl_dout    (romD   ),
	.ioctl_wr      (romW   ),
	.ioctl_upload  (),
	.ioctl_index   (),
	.ioctl_fileext (),
	.ioctl_filesize(),
	.QCSn          (1'b1),
	.QSCK          (1'b1),
	.QDAT          (4'hF),
	.hdd_clk       (1'b0),
	.hdd_cmd_req   (1'b0),
	.hdd_cdda_req  (1'b0),
	.hdd_dat_req   (1'b0),
	.hdd_cdda_wr   (),
	.hdd_status_wr (),
	.hdd_addr      (),
	.hdd_wr        (),
	.hdd_data_out  (),
	.hdd_data_in   (16'd0),
	.hdd_data_rd   (),
	.hdd_data_wr   (),
	.hdd0_ena      (),
	.hdd1_ena      ()
);

reg fddImg = 0;
always @(posedge clock32) if(imgMntd[0]) fddImg <= |imgSize;

reg[2:0] fddCode = 0;
always @(posedge clock32) if(imgMntd[0]) fddCode <= imgSize[18] ? 3'd4 : 3'd2; // 4: 10x512, 2: 9x512

wire fddEna = fddD18[3:0] == 4'b0001 && fddImg && !fddPrep;
wire fddPrep;

wire[31:0] sdLba0;
wire[ 7:0] sdBuffD0;

wire fddDrq;
wire fddIrq;
wire fddRdy;
wire fddDchg;
wire fddDgRs = ~fddD18[6];
wire fddSide = fddD18[4];
wire[7:0] fddQ;

wd17xx fdd0
(
	.clk_sys            (clock32 ),
	.ce                 (fddCe   ),
	.reset              (~reset  ),
	.io_en              (fddIo   ),
	.rd                 (fddRd   ),
	.wr                 (fddWr   ),
	.addr               (fddA    ),
	.din                (fddD10  ),
	.dout               (fddQ    ),
	.drq                (fddDrq  ),
	.intrq              (fddIrq  ),
	.ready_n            (fddRdy  ),
	.wp                 (1'b0    ),
	.ready              (fddEna  ),
	.side               (fddSide ),
	.disk_change_n      (fddDchg ),
	.disk_change_reset_n(fddDgRs ),
	.layout             (1'b0    ),
	.size_code          (fddCode ),
	.busy               (        ),
	.prepare            (fddPrep ),
	.sd_rd              (sdRd[0] ),
	.sd_wr              (sdWr[0] ),
	.sd_ack             (sdAck   ),
	.sd_lba             (sdLba0  ),
	.sd_buff_addr       (sdBuffA ),
	.sd_buff_din        (sdBuffD0),
	.sd_buff_dout       (sdBuffQ ),
	.sd_buff_wr         (sdBuffW ),
	.img_mounted        (imgMntd[0]),
	.img_size           (imgSize[20:0])
);

wire[31:0] sdLba1;
wire[ 7:0] sdBuffD1;

sd_card sd_card
(
	.clk_sys     (clock32   ),
	.sd_rd       (sdRd[1]   ),
	.sd_wr       (sdWr[1]   ),
	.sd_ack      (sdAck     ),
	.sd_lba      (sdLba1    ),
	.sd_busy     (sdBusy    ),
    .sd_conf     (sdConf    ),
    .sd_sdhc     (sdSdhc    ),
    .sd_ack_conf (sdAckCf   ),
	.sd_buff_dout(sdBuffQ   ),
	.sd_buff_wr  (sdBuffW   ),
	.sd_buff_din (sdBuffD1  ),
	.sd_buff_addr(sdBuffA   ),
	.img_mounted (imgMntd[1]),
	.img_size    (imgSize   ),
	.allow_sdhc  (1'b1      ),
	.sd_cs       (sdvCs     ),
	.sd_sck      (sdvCk     ),
	.sd_sdi      (sdvMosi   ),
	.sd_sdo      (sdvMiso   )
);

wire[5:0] ro, go, bo;

osd #(.OSD_AUTO_CE(1'b0)) osd
(
	.clk_sys(clock56),
	.ce     (cep1x  ),
	.SPI_SCK(SPI_SCK),
	.SPI_SS3(SPI_SS3),
	.SPI_DI (SPI_DI ),
	.rotate (2'd0   ),
	.HSync  (hsync  ),
	.VSync  (vsync  ),
	.R_in   ({r,r}  ),
	.G_in   ({g,g}  ),
	.B_in   ({b,b,b}),
	.R_out  (ro     ),
	.G_out  (go     ),
	.B_out  (bo     )
);

scandoubler scandoubler
(
	.clock   (clock56),
	.enable  (~vga    ),
	.ice     (cep1x  ),
	.iblank  ({ vblank, hblank }),
	.isync   ({  vsync,  hsync }),
	.irgb    ({ ro, go, bo }),
	.oce     (cep2x  ),
	.osync   (sync   ),
	.orgb    (rgb    )
);

assign VGA_HS = sync[0];
assign VGA_VS = sync[1];
assign VGA_R  = rgb[17:12];
assign VGA_G  = rgb[11:6];
assign VGA_B  = rgb[5:0];

//-------------------------------------------------------------------------------------------------

wire clock32, locked32;
pll32 pll32(CLOCK_27, clock32, locked32);

wire clock56, locked56;
pll56 pll56(CLOCK_27, clock56, locked56);

wire power = locked32 & locked56;

//-------------------------------------------------------------------------------------------------

reg earIni, earGot;
always @(posedge clock32) if(!earGot) { earIni, earGot } <= { EAR, 1'b1 };

//-------------------------------------------------------------------------------------------------

wire strb;
wire make;
wire[7:0] code;
ps2k keyb(clock32, ps2ko, strb, make, code);

wire[2:0] mbtns;
wire[7:0] xaxis;
wire[7:0] yaxis;
ps2m mouse(clock32, reset, ps2mDQ, ps2mCk, mbtns, xaxis, yaxis);

// wire[7:0] joy1;
// wire[7:0] joy2;
// joystick joystick(clock32, joyCk, joyLd, joyS, joyD, joy1, joy2);

reg F9 = 1'b1;
always @(posedge clock32) if(strb) case(code) 8'h01: F9 <= make; endcase

//-------------------------------------------------------------------------------------------------

wire reset = power && F9 && ready && !iniIo && !romIo;
wire speed = status[5];

wire cecpu;
wire cep1x;
wire cep2x;
wire rfsh;

wire[15:0] memA1;
wire[ 7:0] memQ1;
wire[21:0] memA2;
wire[ 7:0] memD2;
wire[ 7:0] memQ2;
wire       memR2;
wire       memW2;

wire hblank;
wire vblank;
wire hsync;
wire vsync;
wire[2:0] r;
wire[2:0] g;
wire[1:0] b;

wire tape = EAR^earIni;

wire[8:0] left;
wire[8:0] right;

wire      fddCe;
wire      fddIo;
wire      fddRd;
wire      fddWr;
wire[1:0] fddA;
wire[7:0] fddD10;
wire[7:0] fddD18;
wire[7:0] fddQ10 = fddImg ? fddQ : 8'hFF;
wire[7:0] fddQ18 = fddImg ? { fddDrq, fddDchg, 4'b1111, fddIrq, fddRdy } : 8'hFF;

wire sdvCs;
wire sdvCk;
wire sdvMosi;
wire sdvMiso;

ep ep
(
	.clock32(clock32),
	.clock56(clock56),
	.power  (power  ),
	.reset  (reset  ),
	.speed  (speed  ),
	.cecpu  (cecpu  ),
	.cep1x  (cep1x  ),
	.cep2x  (cep2x  ),
	.rfsh   (rfsh   ),
	.memA1  (memA1  ),
	.memQ1  (memQ1  ),
	.memA2  (memA2  ),
	.memD2  (memD2  ),
	.memQ2  (memQ2  ),
	.memR2  (memR2  ),
	.memW2  (memW2  ),
	.hblank (hblank ),
	.vblank (vblank ),
	.hsync  (hsync  ),
	.vsync  (vsync  ),
	.r      (r      ),
	.g      (g      ),
	.b      (b      ),
	.tape   (tape   ),
	.left   (left   ),
	.right  (right  ),
	.strb   (strb   ),
	.make   (make   ),
	.code   (code   ),
	.mbtns  (mbtns  ),
	.xaxis  (xaxis  ),
	.yaxis  (yaxis  ),
	.joy1   (~joy1   ),
	.joy2   (~joy2   ),
	.fddCe  (fddCe  ),
	.fddIo  (fddIo  ),
	.fddRd  (fddRd  ),
	.fddWr  (fddWr  ),
	.fddA   (fddA   ),
	.fddD10 (fddD10 ),
	.fddD18 (fddD18 ),
	.fddQ10 (fddQ10 ),
	.fddQ18 (fddQ18 ),
	.cs     (sdvCs  ),
	.ck     (sdvCk  ),
	.mosi   (sdvMosi),
	.miso   (sdvMiso)
);

//-------------------------------------------------------------------------------------------------

dsg #(8) dsg1(clock32, reset,  left, dsg[1]);
dsg #(8) dsg0(clock32, reset, right, dsg[0]);
//i2s i2so(clock32, i2s, { 1'b0,  left, 6'd0 }, { 1'b0, right, 6'd0 });

`ifdef DEMISTIFY
assign DAC_L = { 1'b0,  left, 6'd0 };
assign DAC_R = { 1'b0, right, 6'd0 };
`endif

assign AUDIO_L = dsg[1];
assign AUDIO_R = dsg[0];

//-------------------------------------------------------------------------------------------------

wire[7:0] maxram
	= status[4:2] == 3'd1 ? 8'h80  //  2MB
	: status[4:2] == 3'd2 ? 8'h40  //  3MB
	: status[4:2] == 3'd3 ? 8'hFC  //  64K
	: status[4:2] == 3'd4 ? 8'hF8  // 128K
	: status[4:2] == 3'd5 ? 8'hF0  // 256K
	: status[4:2] == 3'd6 ? 8'hE0  // 512K
	:                       8'hC0; //  1MB
//	= status[4:2] == 3'd0 ? 8'hC0  //  1MB

reg[7:0] romP = 8'd7;
always @(posedge clock32) if(romIo) romP <= { 5'd0, romA[16:14] };

wire[7:0] memP2 = memA2[21:14];
wire vmm = memP2 >= 8'hFC;
wire ram = memP2 >= maxram;
wire rom = memP2 <= romP;

// reg[18:0] ic;
// always @(posedge clock32, negedge ready) if(!ready) ic <= 1'd0; else if(cecpu) if(iniIo) ic <= ic+1'd1;

// wire       iniIo = !ic[18];
// wire[16:0] iniA  = ic[17:1];
// wire[ 7:0] iniD;
// wire       iniW  = ic[0];
wire       iniIo = 1'b0;
wire       iniA = 1'b0;
wire       iniD = 1'b0;
wire       iniW = 1'b0;

//rom #(128) rom8(clock32, iniA, iniD);
dpr #(64) dpr(clock56, memA1, memQ1, clock32, memA2[15:0], memD2, memW2 && vmm);

wire ready;
wire sdrRf = iniIo ? 1'b1 : rfsh;
wire sdrRd = iniIo ? 1'b0 : memR2 && (ram || rom);
wire sdrWr = iniIo ? iniW : romIo ? romW : memW2 && (ram || (memP2 == 8'h07 && memA2[13]));

wire[23:0] sdrA = { 2'd0, iniIo ? { 5'd0, iniA } : romIo ? romA[21:0] : memA2 };
wire[15:0] sdrD = { 8'd0, iniIo ? iniD : romIo ? romD : memD2 };
wire[15:0] sdrQ;

sdram sdram
(
	.clock  (clock32),
	.reset  (power  ),
	.ready  (ready  ),
	.rfsh   (sdrRf  ),
	.rd     (sdrRd  ),
	.wr     (sdrWr  ),
	.a      (sdrA   ),
	.d      (sdrD   ),
	.q      (sdrQ   ),
	.dramCs (SDRAM_nCS ),
	.dramRas(SDRAM_nRAS),
	.dramCas(SDRAM_nCAS),
	.dramWe (SDRAM_nWE ),
	.dramDQM(dramDQM),
	.dramDQ (SDRAM_DQ ),
	.dramBA (SDRAM_BA ),
	.dramA  (SDRAM_A  )
);

assign memQ2 = rom || ram ? sdrQ[7:0] : 8'hFF;

assign SDRAM_CLK = clock32;
assign SDRAM_CKE = 1'b1;

assign SDRAM_DQML = dramDQM[0];
assign SDRAM_DQMH = dramDQM[1];

//-------------------------------------------------------------------------------------------------

assign LED = 1'b0;

//-------------------------------------------------------------------------------------------------
endmodule
//-------------------------------------------------------------------------------------------------
