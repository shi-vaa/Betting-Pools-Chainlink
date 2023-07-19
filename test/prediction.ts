import { expect, use } from "chai";
import { ethers, waffle, network } from "hardhat";
import { Signer, BigNumber } from "ethers";
import {
  BetszTestToken,
  BetszTestToken__factory,
  Prediction,
  Prediction__factory,
} from "../typechain";
import exp from "constants";
use(waffle.solidity);

describe("Prediction test", () => {
  let betszleToken: BetszTestToken,
    betszleTokenFactory: BetszTestToken__factory;
  let prediction: Prediction, predictionFactory: Prediction__factory;
  let adminSigner: Signer, aliceSigner: Signer, bobSigner: Signer,accounts3: Signer ;
  let admin: string, alice: string, bob: string;
  let footballSportId: BigNumber;
  before(async () => {
    [adminSigner, aliceSigner, bobSigner, accounts3] = await ethers.getSigners();
    admin = await adminSigner.getAddress();
    alice = await aliceSigner.getAddress();
    bob = await bobSigner.getAddress();
    betszleTokenFactory = await ethers.getContractFactory("BetszTestToken");
    predictionFactory = await ethers.getContractFactory("Prediction");
    betszleToken = await betszleTokenFactory.deploy(
      ethers.utils.parseEther("500000")
    );
    prediction = await predictionFactory.deploy(
      betszleToken.address,
      "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
      "0x0bDDCD124709aCBf9BB3F824EbC61C87019888bb",
      Buffer.from("a79e6eaf562f4be981d601cfbf8f8d84"),
      BigNumber.from("100000000000000000")
    );
    betszleToken.transfer(alice, 1000);
    betszleToken.transfer(bob, 1000);
  });
  it("Owner should be able to add sport", async () => {
    var sport = {
      name: "football",
      matchResultUrl:"https://sports.core.api.espn.com/v2/sports/football/leagues/nfl/events/",
    };
    await expect(prediction.addSport(sport)).to.emit(prediction,"SportAdded");
    footballSportId = BigNumber.from(0);
  });
  it("Owner should be able to add team", async () => {
    var team = {
      name: "Cincinati Bengals",
    };
    await expect(prediction.addTeams(footballSportId.toNumber(),13, team)).to.emit(prediction, "TeamAdded");
    await expect(prediction.addTeams(footballSportId.toNumber(),4, team)).to.emit(prediction, "TeamAdded");
    expect(await prediction.teams(footballSportId.toNumber(),13)).to.be.equal("Cincinati Bengals");
  });
  it("Owner should be able to update team", async () => {
    var team = {
      name: "Las Vegas Raiders",
    };
    await expect(prediction.updateTeams(footballSportId, 13, team)).to.emit(
      prediction,
      "TeamUpdated"
    );
  });
  it("Owner should be able to Add Match", async () => {
    var Match = {
      sportId: footballSportId,
      season: 2022, //year
      teamAId: 4,
      teamBId: 13,
      betsStartTime: BigNumber.from(Math.floor((new Date().getTime() / 1000)+60)),
      betsEndTime: BigNumber.from(Math.floor((new Date().getTime() / 1000)) + (24*60*60)),
      endTime: BigNumber.from(Math.floor((new Date().getTime() / 1000)) + (24*60*60)),
      matchResult: 0
    };

    await expect(prediction.addMatch(401326627, Match)).to.emit(
      prediction,
      "MatchAdded"
    );
  });
  // it("Owner should be able to Add Matches", async () => {
  //   const matchIds = [] as any;
  //   const match = [] as any;
  //   for (var i = 2; i <= 6; i++) {
  //     matchIds.push(i);
  //     var Match = {
  //       isBettingOn: true,
  //       season: 1, //year
  //       teamAId: i - 1,
  //       teamBId: i,
  //       startingTime: 300 + i * 2,
  //       poolsStartTime: 300 + i * 2,
  //       poolsEndTime: 1000 + i * 2,
  //     };
  //     match.push(Match);
  //   }
  //   await expect(prediction.addMatches(matchIds, match)).to.emit(
  //     prediction,
  //     "MatchAdded"
  //   );
  // });
  // it("User should be able to Place Bet", async () => {
  //   await betszleToken.connect(bobSigner).approve(prediction.address, 500);
  //   await betszleToken.connect(aliceSigner).approve(prediction.address, 500);
  //   await expect(prediction.connect(aliceSigner).placeBet(1, 1, 1)).to.emit(
  //     prediction,
  //     "BetPlaced"
  //   );
  //   await expect(prediction.connect(bobSigner).placeBet(1, 2, 2)).to.emit(
  //     prediction,
  //     "BetPlaced"
  //   );
  // });
  // it("Owner should not be able to Add Match with same Team ID", async () => {
  //   var Match = {
  //     isBettingOn: true,
  //     season: 1, //year
  //     teamAId: 1,
  //     teamBId: 1,
  //     startingTime: 1,
  //     poolsStartTime: 1,
  //     poolsEndTime: 1000,
  //   };
  //   await expect(prediction.addMatch(7, Match)).to.be.revertedWith(
  //     "Team A and Team B cannot have same Match ID"
  //   );
  // });
  // it("Owner should not be able to Add Match with same Match ID", async () => {
  //   var Match = {
  //     isBettingOn: true,
  //     season: 1, //year
  //     teamAId: 1,
  //     teamBId: 2,
  //     startingTime: 1,
  //     poolsStartTime: 1,
  //     poolsEndTime: 1000,
  //   };
  //   await expect(prediction.addMatch(6, Match)).to.be.revertedWith(
  //     "Match is already added"
  //   );
  // });
  // it("User should not be able to Place Bet when pool time is ended", async () => {
  //   await network.provider.send("evm_increaseTime", [3601]);
  //   await network.provider.send("evm_mine");
  //   await expect(
  //     prediction.connect(aliceSigner).placeBet(1, 1, 1)
  //   ).to.be.revertedWith("Betting is Ended");
  //   await expect(
  //     prediction.connect(bobSigner).placeBet(1, 2, 2)
  //   ).to.be.revertedWith("Betting is Ended");
  // });
});
