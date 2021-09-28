clear all; close all; clc;
SNR = 10; %ОСШ макс
Channel = 4; %количество каналов
chan=1; %количество используемых каналов(берем по 1)
experiment = 1e1; %эксперименты
NumOfBits = 1e2; %длина информационной последовательности
hadamard_matrix = hadamard(64); %Уолш на основе матрицы Адамара, она используется как ПСП,
% т.к. ее строки ортогональны
Ampl = [0, 0.3, 0.6, 0.9]; %амплитуда помехи
% для модулятора/демодулятора
m = 4; % Modulation order
freqsep = 0.1; % Frequency separation (Hz)(частотное разделение)
Nbit =10;
Nsample=floor(NumOfBits/Nbit);% Number of samples per symbol
Ratio = 0.5;

% Параметр для построения импульса
alfa = 3*10^(-22);
Porog_Value = 0.5;
% Длительность импульса
T = 500*10^(-12);
% Шаг по времени
dt = T/20;
% Отсчёты по времени
t0 = -T/2 + dt/2 : dt : T/2 - dt/2;
% Частота дискретизации
Fd = 1/dt;
%% preamble
prb = 10^2;
Preamble_arr = (unidrnd(2, prb, Channel) - 1)';
%prb = randi([0 1],Channel,100);%матрица channel на n из 0 и 1)
%%
for ampl = 1:length(Ampl) %значения помехи
for k=0:SNR
    P=0;
for N=1:experiment   
B = randi([0, 1], Channel, NumOfBits); %матрицаинформационныхпоследовательностей
% добавление CRC функцией Check_CRC
for crc = 1:Channel
CRC(crc,:) = Get_CRC(B(:,crc)); % создание CRC
end
B_to = cat(2,B, CRC); % объединение CRC с данными
B_preamble = cat(2,Preamble_arr,B_to);
S = B_preamble*2 - 1; %преобразование 1/0 в 1/-1 (то есть в ФМ-2)

% Уолш
for n = 1 : Channel%Для каждого канала схема модуляции ФМ-2
for p = 1 : NumOfBits+8 % 
M(n,((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix)) ...
= S(n, p).*hadamard_matrix(n+1,:); %формирование матрицы всех каналов с ПСП
end
end
%%
% Слоты, чипы и период импульсов, порог
Slot = ampl*t0.*exp(-(t0.^2)/(2*alfa));

Chip = Slot(8:13)*10^10;
Slot = Slot*10^10;

%Slot = [Slot Slot*0]'; %1 нс
Slot = [Slot Slot*0 Slot*0 Slot*0 Slot*0]; % 5 нс
% Slot = [Slot Slot*0];    

% Period = length(Slot); % период между импульсами
Eb = sum(Slot.^2)*dt;
Porog = Eb*Porog_Value;

% Модуляция
    % Элемент +1 заменяем на СШП-сигнал
    % Элемент -1 заменяем на отсутствие сигнала
    Signal_tmp = zeros(prb + length(B_to)*length(hadamard_matrix),length(Slot));
    ind_3 = find(M > 0);
    ind_4 = find(M < 0);
    Signal_tmp(ind_3,:) = ones(length(ind_3), 1)*Slot;
%     Signal_tmp(ind_4, :) = ones(length(ind_4), 1)*Slot*0;
    Signal_tmp(ind_4, :) = ones(length(ind_4), 1)*Slot*(-1);
    % Переводим всё в строку
    Signal_tmp2 = reshape(Signal_tmp', 1, size(Signal_tmp, 1)*size(Signal_tmp, 2));

Signal_awgn=awgn(Signal_tmp2, k-8,'measured');%добавление шума в канале связи

% %Формирование ложной информации
% a = randi([0 1],1, length(Signal_awgn));%Ложная информация(необходимая нам)
% A_1=a*2-1;
% for p = 1 : 43200
% A(1,((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix)) ...
% = A_1(1, p).*hadamard_matrix(chan+1,:); %формирование ложного сигнала с ПСП
% end
% A_1=A*Ampl(ampl);
% A_awgn_1=Signal_awgn+A_1; %сложение ложного сигнала с сигналом в канале

% Демодулятор 
% Приём
Rec_Signal = reshape(Signal_awgn', length(Chip), length(Signal_awgn)/length(Chip))';
Rec_Signal = (ones(size(Rec_Signal, 1), 1)*Chip).*Rec_Signal;
Rec_Signal_Value = sum(Rec_Signal, 2);

rec_Coded_arr = zeros(size(Rec_Signal, 1), 1);
for kk = 1 : size(Rec_Signal, 1)
    if (Rec_Signal_Value(kk, :) > Porog)
        rec_Coded_arr(kk) = 1;
    else
        rec_Coded_arr(kk) = -1;
    end
end
rec_Coded_arr_tmp = reshape(rec_Coded_arr, length(hadamard_matrix), length(rec_Coded_arr)/length(hadamard_matrix))';

rec_Decoded_arr_1_tmp = rec_Coded_arr_tmp.*(ones(size(rec_Coded_arr_tmp, 1), 1).*hadamard_matrix(1,:));
rec_Decoded_arr_1_Value = sum(rec_Decoded_arr_1_tmp, 2);
rec_Decoded_arr_1 = (sign(sign(rec_Decoded_arr_1_Value) + 0.5) + 1)/2;

% % далее надо поймать преамбулу
% 
% for kk = 1 : length(rec_Coded_arr) - 30
%     rec_Coded_arr_tmp = reshape(rec_Coded_arr(kk : kk + length(hadamard_matrix)*length(prb) - 1),...
%                                 length(hadamard_matrix), length(prb))';
%     rec_Decoded_arr_1_tmp = rec_Coded_arr_tmp.*(ones(size(rec_Coded_arr_tmp, 1), 1)*hadamard_matrix);
%     rec_Decoded_arr_1_Value = sum(rec_Decoded_arr_1_tmp, 2);
%     rec_Decoded_arr_1 = (sign(sign(rec_Decoded_arr_1_Value) + 0.5) + 1)/2;
%     
%     if sum(rec_Decoded_arr_1.*Preamble_arr') > 12
%         % нашли преамбулу
%         data_start_index_1 = kk + length(prb);
%         break;        
%     end
% end

rec_Coded_arr = rec_Coded_arr';
%%Прием
for p = 1 : length(M)
A_awgn_had(1,((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix)) ...
= rec_Coded_arr(1,((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix)).*hadamard_matrix(chan+1,:);%умножениеобщегополученногосигналанаПСП
 A_awgn_had_sum(1,p)=sum(A_awgn_had(1,((p-1)*length(hadamard_matrix)+1):p*length(hadamard_matrix)));%Суммирование
end

%%РУ
ReshU=(sign(A_awgn_had_sum)+1)/2;
ReshU = ReshU(1,101:end);
for r = 1:length(ReshU)
    if (ReshU(:,r) >= Porog)
        ReshU(:,r) = 1;
    end
end
Signal_3= (S(chan,:)+1)/2;
Signal_3 = Signal_3(:,101:end);
 
 % check CRC
 check = Signal_3(:,101:end)-B_to(1,101:end);%если все 0 то сумма верна
if check == 0
 [error,~]=biterr(Signal_3(:,1:100), ReshU(1,1:100));
else
  printf('error in check CRC')
end
P=P+error/NumOfBits;
end
%Подсчетвероятностей
P1(1,k+1)=P/experiment;
end
P2(ampl,:)=P1(1,:);
end
%Графическое изображение
% figure
% subplot(2,1,1),plot(S), title('channels')
% subplot(2,1,2),plot(Signal, 'b'), title('Signal')
% figure
% subplot(2,1,1),plot(Signal_awgn), title('Signal awgn')
% %subplot(2,1,2),plot(), title('')
% figure
% subplot(2,1,1),plot(Signal_3(:,1:100),'r'), title('Signal')
% subplot(2,1,2),plot(ReshU), title('ReshU')
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
legend('Aп = 0', 'Отношение амплитуд = 0.3', 'Отношение амплитуд = 0.6', 'Отношение амплитуд = 0.9', 'Теоретическое','Location','southwest');
