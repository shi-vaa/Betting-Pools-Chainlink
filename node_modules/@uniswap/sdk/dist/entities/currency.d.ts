/**
 * A currency is any fungible financial instrument on Ethereum, including Ether and all ERC20 tokens.
 *
 * The only instance of the base class `Currency` is Ether.
 */
export declare class Currency {
    readonly decimals: number;
    readonly symbol?: string;
    readonly name?: string;
    static readonly ETHER: Currency;
    protected constructor(decimals: number, symbol?: string, name?: string);
}
declare const ETHER: Currency;
export { ETHER };
