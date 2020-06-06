{ pkgs, lib, cfg }:

with lib;

let
  levelOption = types.submodule {
    options = {
      jigo = mkOption { type = types.bool; default = false; };
      model = mkOption { type = types.str; };
      config = mkOption {
        type = defaultOptions;
        default = {};
      };
    };
  };

  modelOption = types.submodule {
    options = {
      uuid = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      url = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      sha256 = mkOption { type = types.str; };
    };
  };

  mkOptional = optionalType: description:
    mkOption { type = (types.nullOr optionalType); default = null; inherit description; };

  defaultOptions = types.submodule {
    options = with types;
      let uint = ints.positive;
      in {
        #
        # Logs
        #
        logFile = mkOptional str
          "Where to output log?";
        logAllGTPCommunication =
          mkOptional bool "Should all GTP communication be logged?";
        logSearchInfo = mkOptional bool
          "Should search details be logged?";
        logToStderr = mkOptional bool
          "Should the log be sent to stderr?";

        #
        # Rules
        #
        koRule =
          mkOptional (enum [ "SIMPLE" "POSITIONAL" "SITUATIONAL" ])
          "Default rule for ko";
        scoringRule = mkOptional (enum [ "AREA" "TERRITORY" ])
          "Default scoring rule";
        taxRule = mkOptional (enum [ "NONE" "SEKI" "ALL" ])
          "Default taxation rule";
        multiStoneSuicideLegal = mkOptional bool
          "Is multi-stone suicide legal?";
        hasButton = mkOptional bool
          " ??? ";
        whiteHandicapBonus = mkOptional (enum [ "0" "N" "N-1" ])
          " ??? ";

        #
        # Behavior
        #
        allowResignation = mkOptional bool
          "Should Kata be allowed to resign?";
        resignThreshold = mkOptional types.float
          "Win/Loss threshold to consider resignation";
        resignConsecTurns = mkOptional uint
          "Number of losing turns before resigning";

        #
        # Handicap
        #
        dynamicPlayoutDoublingAdvantageCapPerOppLead = mkOptional float
          "Makes katago dynamically adjust to play more aggressively in handicap games based on the handicap and the current state of the game.";
        playoutDoublingAdvantagePla = mkOptional (enum [ "WHITE" "BLACK" ])
          "Controls which side dynamicPlayoutDoublingAdvantageCapPerOppLead or playoutDoublingAdvantage applies to.";

        #
        # Misc
        #

        avoidMYTDaggerHack = mkOptional bool
          "Avoid a particular joseki that some KataGo nets misevaluate and improve opening diversity versus some particular other bots that like to play it all the time.";

        #
        # Limits
        #

        analysisPVLen = mkOptional uint
          "Number moves to show in variation analysis.";
        maxVisits = mkOptional uint
          "If provided, limit maximum number of root visits per search to this much.";
        maxPlayouts = mkOptional uint
          "If provided, limit maximum number of new playouts per search to this much.";
        maxTime = mkOptional float
          "If provided, cap search time at this many seconds.";
        ponderingEnabled = mkOptional bool
          "Ponder on the opponent's turn?";
        maxTimePondering = mkOptional uint
          "If provided, limit time pondering during opponent's turn.";
        numSearchThreads = mkOptional uint
          "Number of threads to use in search";
        searchFactorAfterOnePass = mkOptional float
          "Play a little faster if the opponent passed, for friendliness.";
        searchFactorAfterTwoPass = mkOptional float
          "Play a little faster if the opponent passed twice, for friendliness.";
        searchFactorWhenWinning = mkOptional float
          "Play a little faster if dominating, for friendliness";
        searchFactorWhenWinningThreshold = mkOptional float
          "When to consider the game to be dominated";
        lagBugger = mkOptional float
          "Number of seconds to buffer for lag for GTP time controls";

        #
        # GPU
        #
        nnMaxBatchSize = mkOptional uint
          "Maximum number of positions to send to a single GPU at once.";
        nnCacheSizePowerOfTwo = mkOptional uint "Cache up to (2 ** this) many neural net evaluations in case of transpositions in the tree.";
        nnMutexPoolSizePowerOfTwo = mkOptional uint
          "Size of mutex pool for nnCache is (2 ** this).";
        numNNServerThreadsPerModel = mkOptional uint
          " ??? ";
        openclDeviceToUseThread0 = mkOptional ints.unsigned
          "Which OpenCL device to use.";

        extraConfig = mkOption {
          type = str;
          description = "Extra configuration.";
          default = "";
        };
      };
  };

in {
  enable = mkEnableOption "katago";

  version = mkOption {
    type = types.str;
    default = "v1.4.0";
  };

  releaseUrl = mkOption {
    type = types.str;
    default = "https://d3dndmfyhecmj0.cloudfront.net/g170/neuralnets";
  };

  models = mkOption {
    type = types.attrsOf modelOption;
    default = {
      best = {
        url = "g170-b40c256x2-s3708042240-d967973220.zip";
        sha256 = "05xcsix5g36bicgj1js7rhm9cx953zg7zls0yqxzrm6lkg57s6jb";
      };
      dumb = {
        url = "g170-b6c96-s175395328-d26788732.bin.gz";
        sha256 = "1cb045x36kwwcjr9q8iy2b8i1641mdj765xbss2x6r13czsdszzm";
      };
    };
  };

  defaults = mkOption {
    type = defaultOptions;
    default = {};
  };

  variants = let
    quick  = {
      maxTime = 0.2;
    };
    slow = {
      maxTime = 1.0;
    };
  in mkOption {
    type = types.attrsOf levelOption;
    default = {
      "jigo-quick" = { model = "best"; config = quick; jigo = true; };
      "hard-quick" = { model = "best"; config = quick; };
      "dumb-quick" = { model = "dumb"; config = quick; };
      "hard-slow" = { model = "best"; config = slow; };
      "dumb-slow" = { model = "dumb"; config = slow; };
    };
  };
}

