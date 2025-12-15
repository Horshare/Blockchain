import { ethers } from "hardhat";

async function main() {
  const registryAddr = process.env.HORSE_REGISTRY!;
  if (!registryAddr) throw new Error("Missing HORSE_REGISTRY in .env");

  const tokenId = 1n;

  // Recomendado: URI padrão IPFS (independe de gateway)
  const newTokenURI =
    "ipfs://bafkreifzmlgn4ixwcnu2ppcvwrqdrk7utscjvvof6dyck6swv5bxukdkkq";

  const registry = await ethers.getContractAt("HorseRegistry", registryAddr);

  const tx = await registry.updateTokenURI(tokenId, newTokenURI);
  const rc = await tx.wait();

  console.log("✅ tokenURI atualizado!");
  console.log("Token ID:", tokenId.toString());
  console.log("New tokenURI:", newTokenURI);
  console.log("Tx hash:", rc?.hash);
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
