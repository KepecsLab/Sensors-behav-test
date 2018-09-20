clear all
close all
clc

thresprob=0.8;
thresroc=0.7;
flist = textread(['all.txt'],'%s');

for f =1:length(flist)
    load (flist{f})
    [decision(f) parameters{f}]=perftest(SessionData,thresprob,thresroc)
end