% Формирование преамбулы для данных
clear all; close all; clc;
% Данные
SNR = 10; %ОСШ макс
Channel = 16; %количество каналов
chan=1; %количество используемых каналов(берем по 1)
experiment = 1e3; %эксперименты
NumOfBits = 1e3; %длина информационной последовательности
hadamard_matrix = hadamard(16); %Уолш на основе матрицы Адамара, она используется как ПСП,
% т.к. ее строки ортогональны
Ampl = [0.5, 0.6, 0.7, 0.8, 0.9]; %амплитуда помехи 
Chanel = 16;
t = 0:0.001:1;
Mod = 2;
Porog = 0.5;
%Графики хорошие надо поиграться с Уолшем, 
%%
for ampl = 1:length(Ampl) %значения помехи
for k=0:SNR
    P=0;
for N=1:experiment
     i=i+1;
B = randi([0, 1], NumOfBits, Channel); %матрицаинформационныхпоследовательностей
% добавление CRC функцией Check_CRC
for crc = 1:Channel
CRC(:,crc) = Get_CRC(B(:,crc)); % создание CRC
end
B_to = cat(2,B', CRC'); % объединение CRC с данными
B_to = B_to';

S = B_to*2 - 1; %преобразование 1/0 в 1/-1 (то есть в ФМ-2)

% Уолш
for n = 1 : Channel%Для каждого канала схема модуляции ФМ-2
for p = 1 : NumOfBits+8 % 
M(((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix),n) ...
= S(p, n).*hadamard_matrix(:,n); %формирование матрицы всех каналов с ПСП
end
end
M = (sign(M)+1)/2;
%% preamble
Preamble_arr = (unidrnd(2, length(M), 1) - 1)';
% Добавление преамбулы
M_preamble = M.*Preamble_arr'; % NumOfBits x Channel

% модуляция
modulation = pskmod(M,Mod);


 %Формирование ложной информации
a = randi([0 1], 1, length(modulation));%Ложная информация(необходимая нам)
A_1=a*2-1;
for p = 1 : length(B_to)
A(1,((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix)) ...
= A_1(1, p).*hadamard_matrix(chan+1,:); %формирование ложного сигнала с ПСП
end
A_1=A*Ampl(ampl);


A_awgn_1=modulation+A_1'; %сложение ложного сигнала с сигналом в канале


% канал
Signal_awgn = awgn(A_awgn_1,k-8,'measured');%добавление шума в канале связи

% демодуляция
demodulation = pskdemod(Signal_awgn,Mod);

demodulation = demodulation*2 - 1; %преобразование 1/0 в 1/-1 (то есть в ФМ-2)

demodulation = demodulation';
for n = 1 : Channel%Для каждого канала схема модуляции ФМ-2
for p = 1 : NumOfBits+8
M1(n,((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix)) ...
= demodulation(n,((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix)).*hadamard_matrix(n,:);%умножениеобщегополученногосигналанаПСП
M1_sum(n,p)=sum(M1(n ,((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix)));%Суммирование
end
end

ReshU=(sign(M1_sum)+1)/2;
B_to = B_to';
 % check CRC
 check = ReshU(:,1001:end)-B_to(:,1001:end);%если все 0 то сумма верна
if check == 0
 for r = 1:length(ReshU)
    if (ReshU(:,r) >= Porog)
        ReshU(:,r) = 1;
    end
 end
 else
  fprintf('error in check CRC')
end

ReshU = ReshU';

[error,~]=biterr(B_to', logical(ReshU));
P=P+error/NumOfBits;
end
P1(1,k+1)=P/experiment;
end
P2(ampl,:)=P1(1,:);
end
figure
for i =1:length(Ampl)
semilogy(0:SNR, P2(i,:),'LineWidth', 2);%построениедлякаждойамплитуды
    hold on;
end
semilogy(0:SNR, berawgn(0:SNR, 'psk', 2, 'nondiff'), '--k', 'LineWidth', 2);%построениетеоретическойкривой
grid on;
hold on;
xlabel('SNR, dB', 'FontName', 'Times New Roman', 'FontSize', 18);
ylabel('BER', 'FontName', 'Times New Roman', 'FontSize', 18);
legend('Отношение амплитуд = 0.5', 'Отношение амплитуд = 0.6', 'Отношение амплитуд = 0.7',...
    'Отношение амплитуд = 0.8', 'Отношение амплитуд = 0.9', 'Теоретическое','Location','southwest');