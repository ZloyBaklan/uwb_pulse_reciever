function [Flag_isOk, Data] = Check_CRC(InVect, CRC_Size)
% Функция выполняет проверку целостности пакета по заданному значению
% размера блока CRC.
%
% Входные переменные:
% InVect – массив-строка, длина которого д.б. больше CRC_Size,
% первыми следуют полезные биты, далее биты CRC,
% записанные в обратном порядке;
% CRC_Size – размер блока CRC, м.б. равен {24, 16, 12, 8};
% Flag_isOk – флаг проверки целостности пакета, Flag_isOk = true,
% если блок признан безошибочным, Flag_isOk = false
% в противоположном случае.
%
% Выходные переменные:
% Data - если Flag_isOk = true, то Data - массив-строка полезных данных,
% иначе Data = [].

        % D^24 + D^23 + D^6 + D^5 + D + 1
        g_CRC_24 = zeros(1, 25);
        g_CRC_24 (25 - 24) = 1;
        g_CRC_24 (25 - 23) = 1;
        g_CRC_24 (25 - 6)  = 1;
        g_CRC_24 (25 - 5)  = 1;
        g_CRC_24 (25 - 1)  = 1;
        g_CRC_24 (25 - 0)  = 1;

        % D^16 + D^12 + D^5 + 1
        g_CRC_16 = zeros(1, 17);
        g_CRC_16 (17 - 16) = 1;
        g_CRC_16 (17 - 12) = 1;
        g_CRC_16 (17 - 5)  = 1;
        g_CRC_16 (17 - 0)  = 1;

        % D^12 + D^11 + D^3 + D^2 + D + 1
        g_CRC_12 = zeros(1, 13);
        g_CRC_12 (13 - 12) = 1;
        g_CRC_12 (13 - 11) = 1;
        g_CRC_12 (13 - 3)  = 1;
        g_CRC_12 (13 - 2)  = 1;
        g_CRC_12 (13 - 1)  = 1;
        g_CRC_12 (13 - 0)  = 1;

        % D^8 + D^7 + D^4 + D^3 + D + 1
        g_CRC_8 = zeros(1, 9);
        g_CRC_8 (9 - 8) = 1;
        g_CRC_8 (9 - 7) = 1;
        g_CRC_8 (9 - 4) = 1;
        g_CRC_8 (9 - 3) = 1;
        g_CRC_8 (9 - 1) = 1;
        g_CRC_8 (9 - 0) = 1;
        
        %flip CRC of input vector
        InVect(end - CRC_Size + 1 : end) = ...
                fliplr( InVect(end - CRC_Size + 1 : end) );
        
        switch CRC_Size   
                
                case 24
                        [~, Remainder] = ...
                                Polynom_Division(InVect, g_CRC_24);
                case 16
                        [~, Remainder] = ...
                                Polynom_Division(InVect, g_CRC_16);
                case 12
                        [~, Remainder] = ...
                                Polynom_Division(InVect, g_CRC_12);
                case 8
                        [~, Remainder] = ...
                                Polynom_Division(InVect, g_CRC_8);
        end
           
        %return
        Flag_isOk = ~logical(Remainder);
        if Flag_isOk
                Data = InVect(1 : end - CRC_Size);
        else
                Data = [];
        end
        
end


function [Quotient, Remainder] = Polynom_Division(Dividend, Denominator)
% Функция выполняет деление полиномов при этом
% Dividend = Quotient * Denominator + Remainder.
%
% Все переменные – массивы-строки, содержащие значения коэффициентов
% стоящих при степенях полиномов, при этом первый по порядку элемент
% соответствует коэффициенту при старшей степени полинома.
%
% Входные переменные:
% Dividend - делимый полином;
% Denominator – полином-делитель;
%
% Выходные переменные:
% Quotient - полином-частное от деления;
% Remainder - полином-остаток от деления.
%
% Пример: Dividend = x^4 + x^3 + 1 = [1, 1, 0, 0, 1]
% Denominator = x^2 + 1 = [1, 0, 1]
% Quotient = x^2 + x + 1 = [1, 1, 1]
% Remainder = x = [1, 0]

        Quotient = zeros(1, length(Dividend) - length(Denominator) + 1);

        for k = 1 : length(Quotient)

           if Dividend(k)

                Quotient(k) =  1;

                index = k : k + length(Denominator) - 1;
                Dividend(index) = mod(Dividend(index) + Denominator, 2);

           end

        end

        if bi2de( Dividend(k + 1 : end) )
                Remainder = Dividend(k + 1 : end);
        else
                Remainder = 0;
        end

end