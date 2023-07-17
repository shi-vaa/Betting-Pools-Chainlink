import { ethers, run } from "hardhat";
import { BigNumber } from "ethers";
import { Prediction, Prediction__factory } from "../typechain";

async function deploy() {
  const predictionFactory = (await ethers.getContractFactory(
    "Prediction"
  )) as Prediction__factory;
  const prediction = await predictionFactory.deploy(
    "0x9f2040C8f3aF0dC9b01de4730524b711b8cE4564",
    "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
    "0x0bDDCD124709aCBf9BB3F824EbC61C87019888bb",
    Buffer.from("a79e6eaf562f4be981d601cfbf8f8d84"),
    BigNumber.from("100000000000000000")
  );
  console.log("Prediction deployed at", prediction.address);

  function delay(ms: number) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  await delay(10000);

  /**
   * Programmatic verification
   */
  try {
    // verify staking token
    await run("verify:verify", {
      address: prediction.address,
      constructorArguments: [
        "0x9f2040C8f3aF0dC9b01de4730524b711b8cE4564",
        "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
        "0x0bDDCD124709aCBf9BB3F824EbC61C87019888bb",
        Buffer.from("a79e6eaf562f4be981d601cfbf8f8d84"),
        BigNumber.from("100000000000000000"),
      ],
    });
  } catch (e: any) {
    console.error(`error in verifying: ${e.message}`);
  }
}
deploy();
