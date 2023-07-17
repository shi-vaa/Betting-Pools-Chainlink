import { ethers, network } from "hardhat";
import { Signer, BigNumber } from "ethers";
import { ChainId, Token, TokenAmount, Pair } from "@uniswap/sdk";
import {
    Feed,
    Feed__factory,
} from "../typechain";
import { expect } from "chai";
import { string } from "hardhat/internal/core/params/argumentTypes";

describe("Feeding Tests", async () => {
    let owner: Signer,
        accounts1: Signer,
        accounts2: Signer,
        accounts3: Signer,
        accounts4: Signer,
        accounts5: Signer,
        accounts6: Signer,
        feedFactory: Feed__factory,
        feed: Feed;

    before(async () => {
        [owner, accounts1, accounts2, accounts3, accounts4, accounts5] = await ethers.getSigners();
        feedFactory = (await ethers.getContractFactory("Feed")) as Feed__factory;
        feed = await feedFactory.deploy(
            0x326C977E6efc84E512bB9C30f76E30c160eD06FB,
            0xc8D925525CA8759812d0c299B90247917d4d4b7C,
            "99b1b806a8f84b14a254230ccf094747",
            BigNumber.from(100000000000000000);
    });
    describe("Check", async () => {
        it("perform upkeep", async () => {
            var abiEncoder = ethers.utils.defaultAbiCoder
            var encodedData = abiEncoder.encode(["string"],["401326322"])
            console.log(encodedData);
            await feed.connect(owner).performUpkeep(encodedData);
        });
    });
        it("perform upkeep", async () => {
            var abiEncoder = ethers.utils.defaultAbiCoder
            var encodedData = abiEncoder.encode(["string"],["401326322"])
            console.log(encodedData);
            await feed.connect(owner).performUpkeep(encodedData);
        });
});