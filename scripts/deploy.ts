import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);

  // 1) Deploy HorseRegistry(admin = deployer)
  const HorseRegistry = await ethers.getContractFactory("HorseRegistry");
  const registry = await HorseRegistry.deploy(deployer.address);
  await registry.waitForDeployment();
  const registryAddr = await registry.getAddress();
  console.log("HorseRegistry:", registryAddr);

  // 2) Deploy HorseSharesFactory(registry)
  const Factory = await ethers.getContractFactory("HorseSharesFactory");
  const factory = await Factory.deploy(registryAddr);
  await factory.waitForDeployment();
  const factoryAddr = await factory.getAddress();
  console.log("HorseSharesFactory:", factoryAddr);

  console.log("Done.");
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
