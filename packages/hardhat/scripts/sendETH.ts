import { ethers } from "hardhat";

async function main() {
  const [sender] = await ethers.getSigners();
  console.log("Sender Contract Address", sender.address);
  const contractAddress = "0x7969c5eD335650692Bc04293B07F5BF2e7A673C0";

  const tx = await sender.sendTransaction({
    to: contractAddress,
    value: ethers.parseEther("1.0"),
  });

  await tx.wait();
  console.log(`Transaction hash: ${tx.hash}`);
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
