function [decision,parameters] = perftest(SessionData,thresProb,thresROC)
% function [decision,parameters] = perftest(SessionData,thresProb,thresROC)
%
% computes the area under the receiver operating characteristic (ROC) curve
% optionally, provides bootstrapped confidence intervals and plots the curve
%
% note that x and y must exclusively consist of integers!
%
% results validated a) by simulation with normcdf/norminv b) by comparison
% with web-based calculators and c) with code in the MES Toolbox
%
% INPUT ARGUMENTS
% SessionData         SessionData struct written by Bpodr0.9 after behavior
%
% OPTIONAL INPUT ARGUMENTS
% thresProb           probability threshold for "acceptable behavior"
% thresROC            auROC threshold for difference between licking to two
%                     cues
%
% OUTPUT ARGUMENTS
% decision      0 or 1 indicating whether behavior met threshold
% parameters    2x5 vector holding test stats
%
% Sarah Starosta, August 2018
%
% HISTORY
% Sep 2018  ETG   initiated version control
%           ETG   all comments

%% use default threshold values if none provided
if nargin == 1
    thresProb = 0.8;
    thresROC  = 0.7;
end

%% Loop through trials to get lick data from Bpod struct
for i=1:length(SessionData.RawEvents.Trial)
    % define epochs during each trial: "pre", "sound", "reward"
    
    % the "pre" epoch is the 0.5 seconds prior to sound delivery
    preStart = SessionData.RawEvents.Trial{1,i}.States.SoundDelivery(1)-0.5;
    preStop  = SessionData.RawEvents.Trial{1,i}.States.SoundDelivery(1);
    % the "sound" epoch is 1 second long and starts at the the last 0.2 
    % seconds of the 0.5-second-long sound cue
    soundStart = SessionData.RawEvents.Trial{1,i}.States.SoundDelivery(1)+0.3;
    soundStop  = SessionData.RawEvents.Trial{1,i}.States.SoundDelivery(2)+0.8;
    % "reward" epoch is 0.5 seconds long and starts at the reward delivery
    rewStart = SessionData.RawEvents.Trial{1,i}.States.Outcome(1);
    
    % count licks w/in each epoch
    % create tx4 matrix licks.  columns 1 and 2 are lick rates for "pre"
    % and "sound" epochs.  column 3 is a sum of licks in "reward" epoch.
    % column 4 is TrialType from Bpod
    try
        licks(i,1) = round(...
            sum(SessionData.RawEvents.Trial{1, i}.Events.Port1In > preStart & ...
            SessionData.RawEvents.Trial{1, i}.Events.Port1In < preStop) ...
            / (preStop - preStart) );
        licks(i,2) = round(...
            sum(SessionData.RawEvents.Trial{1, i}.Events.Port1In>soundStart & ...
            SessionData.RawEvents.Trial{1, i}.Events.Port1In < soundStop) ...
            / (soundStop-soundStart) );
        licks(i,3) = ...
            sum(SessionData.RawEvents.Trial{1, i}.Events.Port1In > rewStart & ...
            SessionData.RawEvents.Trial{1, i}.Events.Port1In<rewStart+0.5);
        
    catch
        licks(i,1) = 0;
        licks(i,2) = 0;
        licks(i,3) = 0;
    end
    licks(i,4)=SessionData.TrialTypes(i);
end

% Rearrange licks matrix by trial-type: create kx3 matrix all.  see columns below.
for k=1:5
    trials   = licks(:,4)==k;   % ID trials of type "k"
    all{k,1} = licks(trials,2); % COL1: sound epoch lick rate for k-type trials
    all{k,2} = licks(trials,1); % COL2: pre   epoch lick rate for k-type trials
    all{k,3} = licks(trials,3); % COL3: reward epoch lick SUM for k-type trials
end

%% Run auROC and t-tests

% quantify lick rate differences: rewarded vs. non-rewarded trials
diffStim(1) =   mroc(all{1,1},all{3,1}); %  auROC for lick rate difference in sound epoch between types 1 and 3
diffStim(2) = ttest2(all{1,1},all{3,1}); % t-test for lick rate difference in sound epoch between types 1 and 3
% quantify lick rate differences in rewarded trials: before vs. after cue
diffBase(1) =   mroc(all{1,1},all{1,2}); %  auROC for lick rate difference in type 1 trials between sound and pre epochs
diffBase(2) =  ttest(all{1,1},all{1,2}); % t-test for lick rate difference in type 1 trials between sound and pre epochs

%% Create output
% collect test statistics
parameters([1 3]) = diffStim;
parameters([2 4]) = diffBase;
parameters(5)     = 1/length(all{1,3})*sum(all{1,3}~=0); % session-wide average of reward-collection licks per trial
% evaluate test statistics
parameters(2,1:2) = parameters(1,1:2)>thresROC; % auROC thresholds met?
parameters(2,3:4) = parameters(1,3:4)==1;       % t-test rejects null?
parameters(2,5)   = parameters(5)>thresProb;    % enough reward-collection licks?
% final behavior decision
decision          = sum(parameters(2,:)==1)==5; % all five tests met?

end
