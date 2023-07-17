import { Percent, Trade } from './entities';
export interface TradeOptions {
    allowedSlippage: Percent;
    ttl: number;
    recipient: string;
    feeOnTransfer?: boolean;
}
export interface SwapParameters {
    methodName: string;
    args: (string | string[])[];
    value: string;
}
/**
 * Represents the Uniswap V2 Router, and has static methods for helping execute trades.
 */
export declare abstract class Router {
    /**
     * Cannot be constructed.
     */
    private constructor();
    /**
     * Produces the on-chain method name to call and the hex encoded parameters to pass as arguments for a given trade.
     * @param trade to produce call parameters for
     * @param options options for the call parameters
     */
    static swapCallParameters(trade: Trade, options: TradeOptions): SwapParameters;
}
