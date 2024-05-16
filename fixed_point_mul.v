`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.05.2024 15:37:41
// Design Name: 
// Module Name: fixed_point_mul
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fixed_point_mul#(
          
           parameter int_bits_A = 3,
                     frac_bits_A = 14,
                     int_bits_B = 3,
                     frac_bits_B = 14,
                     int_bits_out = 6,
                     frac_bits_out = 28,
                     intL = int_bits_A + int_bits_B,
                     fracL =  frac_bits_A + frac_bits_B
                     )(
    
                     input wire clk,
                     input wire rst,
                     input wire signed [int_bits_A + frac_bits_A - 1 : 0] A,
                     input wire signed [int_bits_B + frac_bits_B - 1 : 0] B,
                     output wire signed [int_bits_out + frac_bits_out - 1 : 0] product,
                     output reg overflow,
                     output reg underflow);
                     
              //internal registers      
             
               reg [(intL + fracL ) : 0 ] tempprod ;
               reg sign;
               reg [( int_bits_out - 1) : 0] int_bits_outI;
               reg [( frac_bits_out - 1) : 0] frac_bits_outF;
               
          
               always @ (posedge clk) begin
                if(rst) begin
                 tempprod <= 0;
                 end else begin
                   tempprod <= $signed(A) * $signed (B);
                 end
               end 
                   
             //adjesting bitwidth of fractional part
               
                always @(posedge clk) begin
                  if(rst) begin
                        frac_bits_outF <= 0;
                    end else begin
                      if( frac_bits_out > fracL ) begin
                         frac_bits_outF <= {tempprod[fracL - 1 :0] , {( frac_bits_out - fracL){1'b0}}};
                      end else  begin 
                          frac_bits_outF <= tempprod[(fracL - 1) : (fracL - frac_bits_out)];
                       end
                   end
                   end
                    
               always @(posedge clk) begin
                      if (rst) begin
                          sign <= 0;
                      end else begin
                           sign <= A[int_bits_A + frac_bits_A - 1] ^ B[int_bits_B + frac_bits_B - 1];
                       end
               end
                     
               
             // Adjesting bitwidth of integer part
             
             always @ (posedge clk ) begin
                if(rst) begin
                   int_bits_outI <= 0;
                  end else begin
                     if(int_bits_out  >= intL + 1 ) begin
                         int_bits_outI <= {{(int_bits_out - intL){sign}} , tempprod[int_bits_out  + fracL : fracL]};
                     end else begin
                       if(int_bits_out == 1 ) begin
                          int_bits_outI <= tempprod[intL + fracL - 1];
                        end else begin
                          int_bits_outI <= {sign , tempprod[int_bits_out  + fracL - 1 : fracL]};
                        end
                      end
                    end
              end
              
                              
               always @ (posedge clk) begin
                  if (rst) begin
                    overflow <= 0;
                      end else begin
                         if (intL >= int_bits_out) begin
                            if (tempprod[intL + fracL]) begin
                       // Negative result case
                        overflow <= (~&tempprod[intL + fracL : fracL + int_bits_out - 1] != tempprod[intL + fracL]);
                        end else begin
                        // Positive result case
                        overflow <= (|tempprod[intL + fracL - 1 : fracL + int_bits_out - 1]);
                      end
                  end else begin 
                overflow <= 0;
               end
              end
             end
                     
                 
           // checking underflow 
             
                 
//            always @ (posedge clk) begin
//               if (rst) begin
//                  underflow <= 0;
//               end else begin
//                  underflow <= (frac_bits_out == fracL) ? 0 : |tempprod[fracL - frac_bits_out - 1:0];
//               end
//            end
            
            
           always @ (posedge clk) begin
               if (rst) begin
                  underflow <= 0;
              end else begin
                  if (frac_bits_out == fracL) begin
                   underflow <= 0;
                 end else begin
                   underflow <= |tempprod[fracL - frac_bits_out - 1 : 0];
                end
               end
            end
           
             assign product = {frac_bits_outF  , int_bits_outI};
             
               
endmodule
