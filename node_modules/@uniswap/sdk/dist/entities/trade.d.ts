import { TradeType } from '../constants';
import { Currency } from './currency';
import { CurrencyAmount } from './fractions/currencyAmount';
import { Percent } from './fractions/percent';
import { Price } from './fractions/price';
import { Pair } from './pair';
import { Route } from './route';
interface InputOutput {
    readonly inputAmount: CurrencyAmount;
    readonly outputAmount: CurrencyAmount;
}
export declare function inputOutputComparator(a: InputOutput, b: InputOutput): number;
export declare function tradeComparator(a: Trade, b: Trade): number;
export interface BestTradeOptions {
    maxNumResults?: number;
    maxHops?: number;
}
export declare class Trade {
    readonly route: Route;
    readonly tradeType: TradeType;
    readonly inputAmount: CurrencyAmount;
    readonly outputAmount: CurrencyAmount;
    readonly executionPrice: Price;
    readonly nextMidPrice: Price;
    readonly priceImpact: Percent;
    get slippage(): Percent;
    /**
     * Constructs an exact in trade with the given amount in and route
     * @param route route of the exact in trade
     * @param amountIn the amount being passed in
     */
    static exactIn(route: Route, amountIn: CurrencyAmount): Trade;
    /**
     * Constructs an exact out trade with the given amount out and route
     * @param route route of the exact out trade
     * @param amountOut the amount returned by the trade
     */
    static exactOut(route: Route, amountOut: CurrencyAmount): Trade;
    constructor(route: Route, amount: CurrencyAmount, tradeType: TradeType);
    minimumAmountOut(slippageTolerance: Percent): CurrencyAmount;
    maximumAmountIn(slippageTolerance: Percent): CurrencyAmount;
    static bestTradeExactIn(pairs: Pair[], currencyAmountIn: CurrencyAmount, currencyOut: Currency, { maxNumResults, maxHops }?: BestTradeOptions, currentPairs?: Pair[], originalAmountIn?: CurrencyAmount, bestTrades?: Trade[]): Trade[];
    static bestTradeExactOut(pairs: Pair[], currencyIn: Currency, currencyAmountOut: CurrencyAmount, { maxNumResults, maxHops }?: BestTradeOptions, currentPairs?: Pair[], originalAmountOut?: CurrencyAmount, bestTrades?: Trade[]): Trade[];
}
export {};
