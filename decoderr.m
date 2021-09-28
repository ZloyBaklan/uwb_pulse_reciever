hModulator = comm.BPSKModulator;%OOk
hModulator.PhaseOffset = pi; 
hDemodulator = comm.BPSKDemodulator;
hDemodulator.PhaseOffset = pi; 
hDecoder = comm.ViterbiDecoder;
hSoftDemodulator = comm.BPSKDemodulator('PhaseOffset',pi,'DecisionMethod',... 
'Log-likelihood ratio');
snr_vector=1:0.5:7;
i=0;
err1=zeros(1,7);
errhard1=zeros(1,7);
errsoft1=zeros(1,7);
tblen=3;
%OOk
%16 столб
%CRC preambul
%Uolsh
%Мягкие жесткие добавлять только с объяснением
for snr=1:0.5:7
  i=i+1;
   txData = randi([0 1],100000,1);
   trellis = poly2trellis (7, [171 133]);
   codedData = convenc(txData,trellis);
    snrb=snr-10*log10(2);
   %uncoded
   modData = step(hModulator, txData);
   rxSig = awgn(modData,snr,'measured');
   rxData=step(hDemodulator,rxSig);
     err=txData-rxData;
      err1(i)=sum(abs(err));
   %hard
   modDatahard = step(hModulator, codedData);
   rxSig = awgn(modDatahard,snrb,'measured');
   rxDatahard=step(hDemodulator,rxSig);
   decodedDatahard = vitdec(rxDatahard,trellis,tblen,'trunc','hard');
     errhard=txData-decodedDatahard;
      errhard1(i)=sum(abs(errhard));
   %soft
   modDatasoft = step(hModulator, codedData);
   rxSig = awgn(modDatasoft,snrb,'measured');
   rxDatasoft=step(hSoftDemodulator,rxSig);
   [X,Q] = quantiz(rxDatasoft,[-.75 -.5 -.25 0 .25 .5 .75],... 
[7 6 5 4 3 2 1 0]); %? ?
   decodedDatasoft = vitdec(Q',trellis,120,'trunc','soft',3);
      errsoft=txData-decodedDatasoft;
      errsoft1(i)=sum(abs(errsoft));
end             
P=err1./100000;
hardP=errhard1./100000;
softP=errsoft1./100000;
semilogy(snr_vector, P,'-o', snr_vector,hardP,'-*', snr_vector,softP,'-*')
grid
xlabel('snr')
ylabel('P')
legend('uncoded','hard','soft')
%%
