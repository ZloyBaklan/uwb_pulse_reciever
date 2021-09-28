function [code] = Get_CRC(msg)

h = crc.generator('Polynomial','0x1021','InitialState',0,'FinalXOR','0x1d0f');
OUT=generate(h,msg);
CRC2=OUT(end-7:end);
code=CRC2;