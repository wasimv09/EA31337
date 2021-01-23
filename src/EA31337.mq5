//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2021, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+
/*
 *  This file is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.

 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Includes.
#include "include/includes.h"

// EA properties.
#property strict
#property version ea_version
#ifdef __MQL4__
#property description ea_name
#property description ea_desc
#endif
#property link ea_link
#property copyright ea_copy

// Global variables.
EA *ea;

/* EA event handler functions */

/**
 * Initialization function of the expert.
 */
int OnInit() {
  bool _initiated = true;
  PrintFormat("%s v%s (%s) initializing...", ea_name, ea_version, ea_link);
  _initiated &= InitEA();
  _initiated &= InitStrategies();
  if (GetLastError() > 0) {
    ea.Log().Error("Error during initializing!", __FUNCTION_LINE__, Terminal::GetLastErrorText());
  }
  DisplayStartupInfo(true);
  ea.Log().Flush();
  Chart::WindowRedraw();
  if (!_initiated) {
    ea.GetState().Enable(false);
  }
  return (_initiated ? INIT_SUCCEEDED : INIT_FAILED);
}

/**
 * Deinitialization function of the expert.
 */
void OnDeinit(const int reason) { DeinitVars(); }

/**
 * "Tick" event handler function (EA only).
 *
 * Invoked when a new tick for a symbol is received, to the chart of which the Expert Advisor is attached.
 */
void OnTick() {
  EAProcessResult _result = ea.ProcessTick();
  if (_result.stg_processed) {
    if (PrintLogOnChart) {
      Comment("");
      // DisplayInfo();
    }
  }
}

#ifdef __MQL5__
/**
 * "Trade" event handler function (MQL5 only).
 *
 * Invoked when a trade operation is completed on a trade server.
 */
void OnTrade() {}

/**
 * "OnTradeTransaction" event handler function (MQL5 only).
 *
 * Invoked when performing some definite actions on a trade account, its state changes.
 */
void OnTradeTransaction(const MqlTradeTransaction &trans,  // Trade transaction structure.
                        const MqlTradeRequest &request,    // Request structure.
                        const MqlTradeResult &result       // Result structure.
) {}

/**
 * "Timer" event handler function (MQL5 only).
 *
 * Invoked periodically generated by the EA that has activated the timer by the EventSetTimer function.
 * Usually, this function is called by OnInit.
 */
void OnTimer() {}

/**
 * "TesterInit" event handler function (MQL5 only).
 *
 * The start of optimization in the strategy tester before the first optimization pass.
 *
 * Invoked with the start of optimization in the strategy tester.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
void TesterInit() {}

/**
 * "OnTester" event handler function (MQL5 only).
 *
 * Invoked after a history testing of an Expert Advisor on the chosen interval is over.
 * It is called right before the call of OnDeinit().
 *
 * Returns calculated value that is used as the Custom max criterion
 * in the genetic optimization of input parameters.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
double OnTester() { return 1.0; }

/**
 * "OnTesterPass" event handler function (MQL5 only).
 *
 * Invoked when a frame is received during Expert Advisor optimization in the strategy tester.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
void OnTesterPass() {}

/**
 * "OnTesterDeinit" event handler function (MQL5 only).
 *
 * Invoked after the end of Expert Advisor optimization in the strategy tester.
 *
 * @see: https://www.mql5.com/en/docs/basis/function/events
 */
void OnTesterDeinit() {}

/**
 * "OnBookEvent" event handler function (MQL5 only).
 *
 * Invoked on Depth of Market changes.
 * To pre-subscribe use the MarketBookAdd() function.
 * In order to unsubscribe for a particular symbol, call MarketBookRelease().
 */
void OnBookEvent(const string &symbol) {}

/**
 * "OnBookEvent" event handler function (MQL5 only).
 *
 * Invoked by the client terminal when a user is working with a chart.
 */
void OnChartEvent(const int id,          // Event ID.
                  const long &lparam,    // Parameter of type long event.
                  const double &dparam,  // Parameter of type double event.
                  const string &sparam   // Parameter of type string events.
) {}

// @todo: OnTradeTransaction (https://www.mql5.com/en/docs/basis/function/events).
#endif  // end: __MQL5__

/* Custom EA functions */

/**
 * Display info on the chart.
 */
bool DisplayStartupInfo(bool _startup = false, string sep = "\n") {
  string _output = "";
  ResetLastError();
  if (ea.GetState().IsOptimizationMode() || (ea.GetState().IsTestingMode() && !ea.GetState().IsTestingVisualMode())) {
    // Ignore chart updates when optimizing or testing in non-visual mode.
    return false;
  }
  _output += "ACCOUNT: " + ea.Account().ToString() + sep;
  _output += "EA: " + ea.ToString() + sep;
  _output += "MARKET: " + ea.Market().ToString() + sep;
  _output += "SYMBOL: " + ea.SymbolInfo().ToString() + sep;
  _output += "TERMINAL: " + ea.Terminal().ToString() + sep;
  // Print strategies info.
  /*
  int sid;
  Strategy *_strat;
  _output += "STRATEGIES:" + sep;
  for (sid = 0; sid < ea.strats.GetSize(); sid++) {
    _strat = ((Strategy *)strats.GetByIndex(sid));
    _output += _strat.ToString();
  }
  */
  if (_startup) {
    if (ea.GetState().IsTradeAllowed()) {
      if (!Terminal::HasError()) {
        _output += sep + "Trading is allowed, waiting for new bars...";
      } else {
        _output += sep + "Trading is allowed, but there is some issue...";
        _output += sep + Terminal::GetLastErrorText();
        ea.Log().AddLastError(__FUNCTION_LINE__);
      }
    } else if (Terminal::IsRealtime()) {
      _output += sep + StringFormat(
                           "Error %d: Trading is not allowed for this symbol, please enable automated trading or check "
                           "the settings!",
                           __LINE__);
    } else {
      _output += sep + "Waiting for new bars...";
    }
  }
  Comment(_output);
  return !Terminal::HasError();
}

/**
 * Init EA.
 */
bool InitEA() {
  bool _initiated = ea_auth;
  EAParams ea_params(__FILE__, VerboseLevel);
  ea_params.SetChartInfoFreq(PrintLogOnChart ? 2 : 0);
  ea_params.SetName(ea_name);
  ea_params.SetAuthor(StringFormat("%s (%s)", ea_author, ea_link));
  ea_params.SetDesc(ea_desc);
  ea_params.SetVersion(ea_version);
  ea = new EA(ea_params);
  if (!ea.GetState().IsTradeAllowed()) {
    ea.Log().Error("Trading is not allowed for this symbol, please enable automated trading or check the settings!",
                   __FUNCTION_LINE__);
    _initiated = false;
  }
  return _initiated;
}

/**
 * Init strategies.
 */
bool InitStrategies() {
  bool _result = ea_exists;
  long _magic = EA_MagicNumber;
  ResetLastError();
  _result &= ea.StrategyAdd<Stg_AC>(AC_Active_Tf);
  _result &= ea.StrategyAdd<Stg_AD>(AD_Active_Tf);
  _result &= ea.StrategyAdd<Stg_ADX>(ADX_Active_Tf);
  _result &= ea.StrategyAdd<Stg_ATR>(ATR_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Alligator>(Alligator_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Awesome>(Awesome_Active_Tf);
  _result &= ea.StrategyAdd<Stg_BWMFI>(BWMFI_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Bands>(Bands_Active_Tf);
  _result &= ea.StrategyAdd<Stg_BearsPower>(BearsPower_Active_Tf);
  _result &= ea.StrategyAdd<Stg_BullsPower>(BullsPower_Active_Tf);
  _result &= ea.StrategyAdd<Stg_CCI>(CCI_Active_Tf);
  _result &= ea.StrategyAdd<Stg_DeMarker>(DeMarker_Active_Tf);
  // _result &= ea.StrategyAdd<Stg_ElliottWave>(ElliottWave_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Envelopes>(Envelopes_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Force>(Force_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Fractals>(Fractals_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Gator>(Gator_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Ichimoku>(Ichimoku_Active_Tf);
  _result &= ea.StrategyAdd<Stg_MA>(MA_Active_Tf);
  _result &= ea.StrategyAdd<Stg_MACD>(MACD_Active_Tf);
  _result &= ea.StrategyAdd<Stg_MFI>(MFI_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Momentum>(Momentum_Active_Tf);
  _result &= ea.StrategyAdd<Stg_OBV>(OBV_Active_Tf);
  _result &= ea.StrategyAdd<Stg_OsMA>(OSMA_Active_Tf);
  _result &= ea.StrategyAdd<Stg_RSI>(RSI_Active_Tf);
  _result &= ea.StrategyAdd<Stg_RVI>(RVI_Active_Tf);
  _result &= ea.StrategyAdd<Stg_SAR>(SAR_Active_Tf);
  _result &= ea.StrategyAdd<Stg_StdDev>(StdDev_Active_Tf);
  _result &= ea.StrategyAdd<Stg_Stochastic>(Stochastic_Active_Tf);
  _result &= ea.StrategyAdd<Stg_WPR>(WPR_Active_Tf);
  _result &= ea.StrategyAdd<Stg_ZigZag>(ZigZag_Active_Tf);
  _result &= GetLastError() == 0 || GetLastError() == 5053;  // @fixme: error 5053?
  ResetLastError();
  return _result && ea_configured;
}

/**
 * Deinitialize global class variables.
 */
void DeinitVars() { Object::Delete(ea); }
