clear all
close all
tic
x = [1 0 0 0 0 0 0];
l = length(x);
%Скорость передачи данных
sp = input('The Speed of Transmission for the Data');
%Количество пердающихся данных
d = input('The Number of data points you want to transmit');
%Количество попыток передачи данных
lq = input('The number of times you want to transmit the data');
%Фильтрация
filat = input('Do you want to use a filter in this transmisssion, if yes press 1');
%Отношение мощности для импульса RZRZ — это трехуровневый код, 
%обеспечивающий возврат к нулевому уровню после передачи каждого бита информации. 
%Кодирование с возвратом к нулю (Return to Zero). 
%Логическому нулю соответствует положительный импульс, логической единице — отрицательный.
duty = input('What is the duty Ratio you want to use for the RZ pulse, must be less than 1');
i = 0;
while (j < (2^l - 1))
y = xor(x(6),x(7));
temp = [y,x];
x = temp;
j = length(x);
end
data(1:d) = zeros;
while(i<d)
dgen(i+1:i+j) = x;
i = length(dgen);
if (i>d)
data(1:d) = dgen(1:d);
clear dgen temp
t = (1/(32*sp))*(1:1:(32*d));
end
end
% Pulse Generation
% NRZ, RZ
nr(1:32) = ones;
rz(1:32) = zeros;
lo = nearest(duty*32);
rz(1:lo) = ones;
data2 = kron(data,nr);
data3 = kron(data,rz);
subplot(2,1,1),plot(t,data2);hold
grid minor
subplot(2,1,2),plot(t,data3);hold
grid minor
datt2(1:d) = zeros;
datt3(1:d) = zeros;
if (filat == 1)
[B,A] = besself(5,0.8*10^9*2*pi);
[NUMd,DENd] = bilinear(B,A, 32*10^9);
datat2 = filter(NUMd,DENd,data2);
datat3 = filter(NUMd,DENd,data3);
else
datat2 = data2;
datat3 = data3;
end
subplot(2,1,1),plot(t,datat2,'-r');
grid minor
subplot(2,1,2),plot(t,datat3,'-r');
grid minor
h = waitbar(0,'Error Computation');
BER1(1:lq,1:10) = zeros;
BER2(1:lq,1:10) = zeros;
for rep = 1:lq
for SNR = 1:10; 
Pn2 =(sum(datat2.^2)/(length(datat2)))* 1*10^(-SNR/20);
Pn3 =(sum(datat3.^2)/(length(datat3)))* 1*10^(-SNR/20);
dat2 = datat2+(Pn2*randn(1,length(datat2)));
dat3 = datat3+(Pn3*randn(1,length(datat3)));
j = 0;
i =1;
lent = length(datat2);
while(j<=lent-1)
if(dat2(j+16)<0.5)
datt2(i) = 0;
else
datt2(i) =1;
end
if(dat3(j+nearest(lo/2))<0.5)
datt3(i) = 0;
else
datt3(i) =1;
end
j = j+ 32;
i = i+1;
end
BER1(rep,SNR) = mean(data~=datt2)/length(data);
BER2(rep,SNR) = mean(data~=datt3)/length(data);
waitbar((SNR+((rep-1)*10))/(10*lq),h);
end

end
close(h)
BER1x = sum(BER1(1:lq,:))/lq;
BER2x = sum(BER2(1:lq,:))/lq;
figure(2),semilogy(BER1x);
hold
semilogy(BER2x,'-r');
toc