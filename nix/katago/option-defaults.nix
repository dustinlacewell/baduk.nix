{
  logFile = "gtp.log";
  logAllGTPCommunication = true;
  logSearchInfo = true;
  logToStderr = false;

  koRule = "SIMPLE";
  scoringRule = "TERRITORY";
  taxRule = "SEKI";
  multiStoneSuicideLegal = false;
  hasButton = false;
  whiteHandicapBonus = "0";

  allowResignation = true;
  resignThreshold = (-0.9);
  resignConsecTurns = 3;

  dynamicPlayoutDoublingAdvantageCapPerOppLead = 4.0e-2;
  playoutDoublingAdvantagePla = "WHITE";
  avoidMYTDaggerHack = false;
  analysisPVLen = 13;
  ponderingEnabled = false;
  numSearchThreads = 10;
  searchFactorAfterOnePass = 0.5;
  searchFactorAfterTwoPass = 0.25;
  searchFactorWhenWinning = 0.4;
  searchFactorWhenWinningThreshold = 0.95;
  lagBugger = 1.0;

  nnMaxBatchSize = 10;
  nnCacheSizePowerOfTwo = 20;
  nnMutexPoolSizePowerOfTwo = 16;
  numNNServerThreadsPerModel = 1;
  openclDeviceToUseThread0 = 0;
}
