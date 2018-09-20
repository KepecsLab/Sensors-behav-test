function [decision,parameters] = perftest(SessionData,thresprob,thresroc)


for i=1:length(SessionData.RawEvents.Trial)
    prestart=SessionData.RawEvents.Trial{1,i}.States.SoundDelivery(1)-0.5;
    prestop=SessionData.RawEvents.Trial{1,i}.States.SoundDelivery(1);
    soundstart=SessionData.RawEvents.Trial{1,i}.States.SoundDelivery(1)+0.3;
    soundstop=SessionData.RawEvents.Trial{1,i}.States.SoundDelivery(2)+0.8;
    rewstart=SessionData.RawEvents.Trial{1,i}.States.Outcome(1);
    try
        licks(i,1)= round(sum(SessionData.RawEvents.Trial{1, i}.Events.Port1In>prestart &SessionData.RawEvents.Trial{1, i}.Events.Port1In<prestop)/      (prestop-prestart));
        licks(i,2)= round(sum(SessionData.RawEvents.Trial{1, i}.Events.Port1In>soundstart &SessionData.RawEvents.Trial{1, i}.Events.Port1In<soundstop)/   (soundstop-soundstart));
        licks(i,3)= sum(SessionData.RawEvents.Trial{1, i}.Events.Port1In>rewstart &SessionData.RawEvents.Trial{1, i}.Events.Port1In<rewstart+0.5);
        
    catch
        licks(i,1)= 0;
        licks(i,2)=0;
        licks(i,3)=0;
    end
    licks(i,4)=SessionData.TrialTypes(i);
end
%
for k=1:5
    trials=licks(:,4)==k;
    all{k,1}=licks(trials,2);
    all{k,2}=licks(trials,1);
    all{k,3}=licks(trials,3);
end

diffstim(1)=mroc(all{1,1},all{3,1});
diffstim(2)=ttest2(all{1,1},all{3,1});
diffbase(1)=mroc(all{1,1},all{1,2});
diffbase(2)=ttest(all{1,1},all{1,2});

parameters([1 3])=diffstim;
parameters([2 4])=diffbase;
parameters(5)=1/length(all{1,3})*sum(all{1,3}~=0);
parameters(2,1:2)=parameters(1,1:2)>thresroc;
parameters(2,3:4)=parameters(1,3:4)==1;
parameters(2,5)=parameters(5)>thresprob;
decision=sum(parameters(2,:)==1)==5;

