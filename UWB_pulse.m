% program for UWB pulse generation
clc; clear all; close all
tao_m=0.5;
t=-5:.01:5;
op1=(1-4*pi*(t/tao_m).^2);
for i=1:1001
    op2(1,i)=exp(-2*pi*(t(i)/tao_m)^2);
%     f(1,i)=1/t(1,i);
end
op=op1.*op2;
plot(t,op)
xlabel('time');ylabel('Normalized Amplitude');
Title('UWB pulse Gaussian Doublet');
axis([-0.5 0.5 -0.6 1])
% figure
% fr=abs(fft(op));
