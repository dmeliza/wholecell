function [pc8h] = getpc8header(fid);
%GETPC8HEADER Get header information from a pClamp 8.x Axon Binary File (ABF).
%   (version 1.65)
%   pc8h = GETPC8HEADER(FID) returns a structure with all header information.
%   ABF files should be opened with the appropriate machineformat (IEEE floating
%   point with little-endian byte ordering, e.g., fopen(file,'r','l').
%   For a description of the fields, see the "abf.asc" file included with the 
%   "Axon PC File Support Package for Developers".
%
%   FID is an integer file identifier obtained from FOPEN.

%   Adapted from Carsten Hohnke 12/99
%   Dan Meliza $Id$

if fid == -1, % Check for invalid fid.
   error('Invalid fid.');
end
fseek(fid,0,'bof'); % Set the pointer to beginning of the file.

pc8h.size=2048;
pc8h.sFileType=fread(fid,1,'int'); % pointing to byte 0
pc8h.fFileVersionNumber=fread(fid,1,'float'); % 4
pc8h.nOperationMode=fread(fid,1,'short'); % 8
pc8h.lActualAcqLength=fread(fid,1,'int'); % 10
pc8h.nNumPointsIgnored=fread(fid,1,'short'); % 14
pc8h.lActualEpisodes=fread(fid,1,'int'); % 16
pc8h.lFileStartDate=fread(fid,1,'int'); % 20
pc8h.lFileStartTime=fread(fid,1,'int'); % 24
pc8h.lStopwatchTime=fread(fid,1,'int'); % 28
pc8h.fHeaderVersionNumber=fread(fid,1,'float'); % 32
pc8h.nFileType=fread(fid,1,'short'); % 36
pc8h.nMSBinFormat=fread(fid,1,'short'); % 38
pc8h.lDataSectionPtr=fread(fid,1,'int'); % 40
pc8h.lTagSectionPtr=fread(fid,1,'int'); % 44
pc8h.lNumTagEntries=fread(fid,1,'int'); % 48
pc8h.lScopeConfigPtr=fread(fid,1,'int'); % 52
pc8h.lNumScopes=fread(fid,1,'int'); % 56 
pc8h.d_lDACFilePtr=fread(fid,1,'int'); % 60 - depr
pc8h.d_lDACFileNumEpisodes=fread(fid,1,'int'); % 64 -depr
pc8h.sUnused68=fread(fid,4,'char'); % 4char % 68
pc8h.lDeltaArrayPtr=fread(fid,1,'int'); % 72
pc8h.lNumDeltas=fread(fid,1,'int'); % 76
pc8h.lVoiceTagPtr=fread(fid,1,'int'); % 80
pc8h.lVoiceTagEntries=fread(fid,1,'int'); % 84
pc8h.lUnused88=fread(fid,1,'int'); % 88
pc8h.lSynchArrayPtr=fread(fid,1,'int'); % 92
pc8h.lSynchArraySize=fread(fid,1,'int'); % 96
pc8h.nDataFormat=fread(fid,1,'short'); % 100
pc8h.nSimultaneousScan=fread(fid,1,'short'); % 102 -unimpl
pc8h.sUnused102=fread(fid,16,'char'); % 16char % 102
pc8h.nADCNumChannels=fread(fid,1,'short'); % 120
pc8h.fADCSampleInterval=fread(fid,1,'float'); % 122
pc8h.fADCSecondSampleInterval=fread(fid,1,'float'); %  % 126
pc8h.fSynchTimeUnit=fread(fid,1,'float'); % 130
pc8h.fSecondsPerRun=fread(fid,1,'float'); % 134
pc8h.lNumSamplesPerEpisode=fread(fid,1,'int'); % 138
pc8h.lPreTriggerSamples=fread(fid,1,'int'); % 142
pc8h.lEpisodesPerRun=fread(fid,1,'int'); % 146
pc8h.lRunsPerTrial=fread(fid,1,'int'); % 150
pc8h.lNumberOfTrials=fread(fid,1,'int'); % 154
pc8h.nAveragingMode=fread(fid,1,'short'); % 158
pc8h.nUndoRunCount=fread(fid,1,'short'); % 160
pc8h.nFirstEpisodeInRun=fread(fid,1,'short'); % 162
pc8h.fTriggerThreshold=fread(fid,1,'float'); % 164
pc8h.nTriggerSource=fread(fid,1,'short'); % 168
pc8h.nTriggerAction=fread(fid,1,'short'); % 170
pc8h.nTriggerPolarity=fread(fid,1,'short'); % 172
pc8h.fScopeOutputInterval=fread(fid,1,'float'); % 174
pc8h.fEpisodeStartToStart=fread(fid,1,'float'); % 178
pc8h.fRunStartToStart=fread(fid,1,'float'); % 182
pc8h.fTrialStartToStart=fread(fid,1,'float'); % 186
pc8h.lAverageCount=fread(fid,1,'int'); % 190
pc8h.lClockChange=fread(fid,1,'int'); % 194
pc8h.nAutoTriggerStrategy=fread(fid,1,'short'); % 198
pc8h.nDrawingStrategy=fread(fid,1,'short'); % 200
pc8h.nTiledDisplay=fread(fid,1,'short'); % 202
pc8h.nEraseStrategy=fread(fid,1,'short'); % 204
pc8h.nDataDisplayMode=fread(fid,1,'short'); % 206
pc8h.lDisplayAverageUpdate=fread(fid,1,'int'); % 208
pc8h.nChannelStatsStrategy=fread(fid,1,'short'); % 212
pc8h.lCalculationPeriod=fread(fid,1,'int'); % 214
pc8h.lSamplesPerTrace=fread(fid,1,'int'); % 218
pc8h.lStartDisplayNum=fread(fid,1,'int'); % 222
pc8h.lFinishDisplayNum=fread(fid,1,'int'); % 226
pc8h.nMultiColor=fread(fid,1,'short'); % 230
pc8h.nShowPNRawData=fread(fid,1,'short'); % 232
pc8h.fStatisticsPeriod=fread(fid,1,'float'); % 234
pc8h.lStatisticsMeasurements=fread(fid,1,'long'); % 238
pc8h.nStatisticsSaveStrategy=fread(fid,1,'short'); % 240 ?
pc8h.fADCRange=fread(fid,1,'float'); % 244
pc8h.fDACRange=fread(fid,1,'float'); % 248
pc8h.lADCResolution=fread(fid,1,'int'); % 252
pc8h.lDACResolution=fread(fid,1,'int'); % 256
pc8h.nExperimentType=fread(fid,1,'short'); % 260
pc8h.d_nAutosampleEnable=fread(fid,1,'short'); % 262 - depr
pc8h.d_nAutosampleADCNum=fread(fid,1,'short'); % 264 - depr
pc8h.d_nAutosampleInstrument=fread(fid,1,'short'); % 266 -depr
pc8h.d_fAutosampleAdditGain=fread(fid,1,'float'); % 268 -depr
pc8h.d_fAutosampleFilter=fread(fid,1,'float'); % 272 -depr
pc8h.d_fAutosampleMembraneCapacitance=fread(fid,1,'float'); % 276 -depr
pc8h.nManualInfoStrategy=fread(fid,1,'short'); % 280
pc8h.fCellID1=fread(fid,1,'float'); % 282
pc8h.fCellID2=fread(fid,1,'float'); % 286
pc8h.fCellID3=fread(fid,1,'float'); % 290
pc8h.sCreatorInfo=fread(fid,16,'char'); % 16char % 294
pc8h.d_sFileComment=fread(fid,56,'char'); % 56char % 310 -depr
pc8h.sUnused366=fread(fid,12,'char'); % 12char % 366
pc8h.nADCPtoLChannelMap=fread(fid,16,'short'); % 378
pc8h.nADCSamplingSeq=fread(fid,16,'short'); % 410
pc8h.sADCChannelName=fread(fid,16*10,'char'); % 442
pc8h.sADCUnits=fread(fid,16*8,'char'); % 8char % 602
pc8h.fADCProgrammableGain=fread(fid,16,'float'); % 730
pc8h.fADCDisplayAmplification=fread(fid,16,'float'); % 794
pc8h.fADCDisplayOffset=fread(fid,16,'float'); % 858
pc8h.fInstrumentScaleFactor=fread(fid,16,'float'); % 922
pc8h.fInstrumentOffset=fread(fid,16,'float'); % 986
pc8h.fSignalGain=fread(fid,16,'float'); % 1050
pc8h.fSignalOffset=fread(fid,16,'float'); % 1114
pc8h.fSignalLowpassFilter=fread(fid,16,'float'); % 1178
pc8h.fSignalHighpassFilter=fread(fid,16,'float'); % 1242
pc8h.sDACChannelName=fread(fid,4*10,'char'); % 1306
pc8h.sDACChannelUnits=fread(fid,4*8,'char'); % 8char % 1346
pc8h.fDACScaleFactor=fread(fid,4,'float'); % 1378
pc8h.fDACHoldingLevel=fread(fid,4,'float'); % 1394
pc8h.nSignalType=fread(fid,1,'short'); % 12char % 1410
pc8h.sUnused1412=fread(fid,10,'char'); % 10char % 1412
pc8h.nOUTEnable=fread(fid,1,'short'); % 1422
pc8h.nSampleNumberOUT1=fread(fid,1,'short'); % 1424
pc8h.nSampleNumberOUT2=fread(fid,1,'short'); % 1426
pc8h.nFirstEpisodeOUT=fread(fid,1,'short'); % 1428
pc8h.nLastEpisodeOUT=fread(fid,1,'short'); % 1430
pc8h.nPulseSamplesOUT1=fread(fid,1,'short'); % 1432
pc8h.nPulseSamplesOUT2=fread(fid,1,'short'); % 1434
pc8h.nDigitalEnable=fread(fid,1,'short'); % 1436
pc8h.d_nWaveformSource=fread(fid,1,'short'); % 1438
pc8h.nActiveDACChannel=fread(fid,1,'short'); % 1440
pc8h.d_nInterEpisodeLevel=fread(fid,1,'short'); % 1442
pc8h.d_nEpochType=fread(fid,10,'short'); % 1444
pc8h.d_fEpochInitLevel=fread(fid,10,'float'); % 1464
pc8h.d_fEpochLevelInc=fread(fid,10,'float'); % 1504
pc8h.d_nEpochInitDuration=fread(fid,10,'short'); % 1544
pc8h.d_nEpochDurationInc=fread(fid,10,'short'); % 1564
pc8h.nDigitalHolding=fread(fid,1,'short'); % 1584
pc8h.nDigitalInterEpisode=fread(fid,1,'short'); % 1586
pc8h.nDigitalValue=fread(fid,10,'short'); % 1588
pc8h.sUnavailable1608=fread(fid,4,'char'); % 1608
pc8h.sUnused1612=fread(fid,8,'char'); % 8char % 1612
pc8h.d_fDACFileScale=fread(fid,1,'float'); % 1620
pc8h.d_fDACFileOffset=fread(fid,1,'float'); % 1624
pc8h.sUnused1628=fread(fid,2,'char'); % 2char % 1628
pc8h.d_nDACFileEpisodeNum=fread(fid,1,'short'); % 1630
pc8h.d_nDACFileADCNum=fread(fid,1,'short'); % 1632
pc8h.d_sDACFileName=fread(fid,12,'char'); % 12char % 1634
pc8h.sDACFilePath=fread(fid,60,'char'); % 60char % 1646
pc8h.sUnused1706=fread(fid,12,'char'); % 12char % 1706
pc8h.d_nConditEnable=fread(fid,1,'short'); % 1718
pc8h.d_nConditChannel=fread(fid,1,'short'); % 1720
pc8h.d_lConditNumPulses=fread(fid,1,'int'); % 1722
pc8h.d_fBaselineDuration=fread(fid,1,'float'); % 1726
pc8h.d_fBaselineLevel=fread(fid,1,'float'); % 1730
pc8h.d_fStepDuration=fread(fid,1,'float'); % 1734
pc8h.d_fStepLevel=fread(fid,1,'float'); % 1738
pc8h.d_fPostTrainPeriod=fread(fid,1,'float'); % 1742
pc8h.d_fPostTrainLevel=fread(fid,1,'float'); % 1746
pc8h.sUnused1750=fread(fid,12,'char'); % 12char % 1750
pc8h.d_nParamToVary=fread(fid,1,'short'); % 1762
pc8h.d_sParamValueList=fread(fid,80,'char'); % 80char % 1764
pc8h.nAutopeakEnable=fread(fid,1,'short'); % 1844
pc8h.nAutopeakPolarity=fread(fid,1,'short'); % 1846
pc8h.nAutopeakADCNum=fread(fid,1,'short'); % 1848
pc8h.nAutopeakSearchMode=fread(fid,1,'short'); % 1850
pc8h.lAutopeakStart=fread(fid,1,'int'); % 1852
pc8h.lAutopeakEnd=fread(fid,1,'int'); % 1856
pc8h.nAutopeakSmoothing=fread(fid,1,'short'); % 1860
pc8h.nAutopeakBaseline=fread(fid,1,'short'); % 1862
pc8h.nAutopeakAverage=fread(fid,1,'short'); % 1864
pc8h.sUnused1866=fread(fid,2,'char'); % 2char % 1866
pc8h.lAutopeakBaselineStart=fread(fid,1,'int'); % 1868
pc8h.lAutopeakBaselineEnd=fread(fid,1,'int'); % 1872
pc8h.lAutopeakMeasurements=fread(fid,1,'int'); % 1876
pc8h.nArithmeticEnable=fread(fid,1,'short'); % 1880
pc8h.fArithmeticUpperLimit=fread(fid,1,'float'); % 1882
pc8h.fArithmeticLowerLimit=fread(fid,1,'float'); % 1886
pc8h.nArithmeticADCNumA=fread(fid,1,'short'); % 1890
pc8h.nArithmeticADCNumB=fread(fid,1,'short'); % 1892
pc8h.fArithmeticK1=fread(fid,1,'float'); % 1894
pc8h.fArithmeticK2=fread(fid,1,'float'); % 1898
pc8h.fArithmeticK3=fread(fid,1,'float'); % 1902
pc8h.fArithmeticK4=fread(fid,1,'float'); % 1906
pc8h.sArithmeticOperator=fread(fid,2,'char'); % 2char % 1910
pc8h.sArithmeticUnits=fread(fid,8,'char'); % 8char % 1912
pc8h.fArithmeticK5=fread(fid,1,'float'); % 1920
pc8h.fArithmeticK6=fread(fid,1,'float'); % 1924
pc8h.nArithmeticExpression=fread(fid,1,'short'); % 1928
pc8h.sUnused1930=fread(fid,2,'char'); % 2char % 1930
pc8h.d_nPNEnable=fread(fid,1,'short'); % 1932
pc8h.nPNPosition=fread(fid,1,'short'); % 1934
pc8h.d_nPNPolarity=fread(fid,1,'short'); % 1936
pc8h.nPNNumPulses=fread(fid,1,'short'); % 1938
pc8h.d_nPNADCNum=fread(fid,1,'short'); % 1940
pc8h.d_fPNHoldingLevel=fread(fid,1,'float'); % 1942
pc8h.fPNSettlingTime=fread(fid,1,'float'); % 1946
pc8h.fPNInterpulse=fread(fid,1,'float'); % 1950
pc8h.sUnused1954=fread(fid,12,'char'); % 12char % 1954
pc8h.nListEnable=fread(fid,1,'short'); % 1966
pc8h.sUnused1966=fread(fid,80,'char'); % 80char % 1968

% v 1.65 additions
pc8h.lDACFilePtr=fread(fid,2,'int'); % 2long 2048
pc8h.lDACFileNumEpisodes=fread(fid,2,'int'); % 2long 2056
pc8h.sUnused2=fread(fid,10,'char'); % 2064
pc8h.fDACCalibrationFactor=fread(fid,4,'float'); % 4float 2074
pc8h.fDACCalibrationOffset=fread(fid,4,'float'); % 4float 2090
pc8h.sUnused7=fread(fid,190,'char'); % 2106
pc8h.nWaveformEnable=fread(fid,2,'short'); % 2short 2296
pc8h.nWaveformSource=fread(fid,2,'short'); % 2short 2300
pc8h.nInterEpisodeLevel=fread(fid,2,'short'); %2short 2304
pc8h.nEpochType=fread(fid,2*10,'short'); % 2x10short 2308
pc8h.fEpochInitLevel=fread(fid,2*10,'float'); % 2x10float 2348
pc8h.fEpochLevelInc=fread(fid,2*10,'float'); %2x10float 2428
pc8h.lEpochInitDuration=fread(fid,2*10,'int'); % 2x10long 2508
pc8h.lEpochDuration=fread(fid,2*10,'int'); % 2x10long 2588
pc8h.sUnused9=fread(fid,40,'char'); % 2668
pc8h.fDACFileScale=fread(fid,2,'float'); %2float 2708
pc8h.fDACFileOffset=fread(fid,2,'float'); %2float 2716
pc8h.lDACFileEpisodeNum=fread(fid,2,'int'); %2int 2724
pc8h.nDACFileADCNum=fread(fid,2,'short'); %2short 2732
pc8h.sDACFilePath=fread(fid,2*256,'char'); %2x256char 2736
pc8h.sUnused10=fread(fid,12,'char'); % 3248
pc8h.nConditEnable=fread(fid,2,'short'); %3260
pc8h.lConditNumPulses=fread(fid,2,'int'); %3264
pc8h.fBaselineDuration=fread(fid,2,'float'); %3272
pc8h.fBaselineLevel=fread(fid,2,'float'); %3280
pc8h.fStepDuration=fread(fid,2,'float'); %3288
pc8h.fStepLevel=fread(fid,2,'float'); %3296
pc8h.fPostTrainPeriod=fread(fid,2,'float'); %3304
pc8h.fPostTrainLevel=fread(fid,2,'float'); %3312
pc8h.nUnused11=fread(fid,2,'short'); %3320
pc8h.sUnused11=fread(fid,36,'char'); %3324
pc8h.nULEnable=fread(fid,4,'short'); %3360
pc8h.nULParamToVary=fread(fid,4,'short'); %3368
pc8h.sULParamValueList=fread(fid,4*256,'char'); %3376
pc8h.sUnused12=fread(fid,56,'char'); %4400
pc8h.nPNEnable=fread(fid,2,'short'); %4456
pc8h.nPNPolarity=fread(fid,2,'short'); %4460
pc8h.nPNADCNum=fread(fid,2,'short'); %4464
pc8h.fPNHoldingLevel=fread(fid,2,'float');%4468
pc8h.sUnused15=fread(fid,36,'char'); %4476
pc8h.nTelegraphEnable=fread(fid,16,'short'); %4512
pc8h.nTelegraphInstrument=fread(fid,16,'short'); %4544
pc8h.fTelegraphAdditGain=fread(fid,16,'float'); %4576
pc8h.fTelegraphFilter=fread(fid,16,'float'); %4640
pc8h.fTelegraphMembraneCap=fread(fid,16,'float'); %4704
pc8h.nTelegraphMode=fread(fid,16,'short'); %4768
pc8h.nManualTelegraphStrategy=fread(fid,16,'short'); %4800
pc8h.nAutoAnalyseEnable=fread(fid,1,'short'); %4832
pc8h.sAutoAnalysisMacroName=fread(fid,64,'char'); %4834
pc8h.sProtocolPath=fread(fid,256,'char'); %4898
pc8h.sFileComment=fread(fid,128,'char'); %5154
pc8h.sUnused6=fread(fid,128,'char'); %5282
pc8h.sUnused2048=fread(fid,734,'char'); %5410






