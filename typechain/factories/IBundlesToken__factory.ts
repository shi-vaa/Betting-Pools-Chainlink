/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import { Provider } from "@ethersproject/providers";
import type { IBetszToken, IBetszTokenInterface } from "../IBetszToken";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "user",
        type: "address",
      },
      {
        internalType: "bytes",
        name: "depositData",
        type: "bytes",
      },
    ],
    name: "deposit",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
];

export class IBetszToken__factory {
  static readonly abi = _abi;
  static createInterface(): IBetszTokenInterface {
    return new utils.Interface(_abi) as IBetszTokenInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): IBetszToken {
    return new Contract(address, _abi, signerOrProvider) as IBetszToken;
  }
}
