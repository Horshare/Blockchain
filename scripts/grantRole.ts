import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Concedendo roles com a conta:", deployer.address);

  // Endereço do contrato HorseRegistry deployado
  const HORSE_REGISTRY_ADDRESS = "0x4f7dBB2F9353Bfdd95BD153912405c2559Bb6A3B";
  
  // Endereço da carteira do backend que precisa da role
  const BACKEND_WALLET_ADDRESS = "0x9B5d0F6CDdCd7f059f681406D8B72eDbC1C0619D";

  // Conectar ao contrato
  const HorseRegistry = await ethers.getContractFactory("HorseRegistry");
  const registry = HorseRegistry.attach(HORSE_REGISTRY_ADDRESS);

  // Hash da role REGISTRAR_ROLE
  const REGISTRAR_ROLE = ethers.keccak256(ethers.toUtf8Bytes("REGISTRAR_ROLE"));

  console.log("\n📋 Informações:");
  console.log("- Contrato HorseRegistry:", HORSE_REGISTRY_ADDRESS);
  console.log("- Carteira Backend:", BACKEND_WALLET_ADDRESS);
  console.log("- REGISTRAR_ROLE hash:", REGISTRAR_ROLE);

  // Verificar se já tem a role
  const hasRole = await registry.hasRole(REGISTRAR_ROLE, BACKEND_WALLET_ADDRESS);
  
  if (hasRole) {
    console.log("\n✅ Backend já possui REGISTRAR_ROLE!");
  } else {
    console.log("\n⏳ Concedendo REGISTRAR_ROLE ao backend...");
    
    const tx = await registry.grantRole(REGISTRAR_ROLE, BACKEND_WALLET_ADDRESS);
    console.log("📤 Transação enviada:", tx.hash);
    
    await tx.wait();
    console.log("✅ REGISTRAR_ROLE concedida com sucesso!");
  }

  // Verificar novamente
  const hasRoleAfter = await registry.hasRole(REGISTRAR_ROLE, BACKEND_WALLET_ADDRESS);
  console.log("\n🔍 Verificação final:");
  console.log("- Backend tem REGISTRAR_ROLE?", hasRoleAfter);

  // Mostrar todas as roles do backend
  const DEFAULT_ADMIN_ROLE = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const PAUSER_ROLE = ethers.keccak256(ethers.toUtf8Bytes("PAUSER_ROLE"));

  const hasAdmin = await registry.hasRole(DEFAULT_ADMIN_ROLE, BACKEND_WALLET_ADDRESS);
  const hasPauser = await registry.hasRole(PAUSER_ROLE, BACKEND_WALLET_ADDRESS);

  console.log("\n📊 Todas as roles do backend:");
  console.log("- DEFAULT_ADMIN_ROLE:", hasAdmin ? "✅" : "❌");
  console.log("- REGISTRAR_ROLE:", hasRoleAfter ? "✅" : "❌");
  console.log("- PAUSER_ROLE:", hasPauser ? "✅" : "❌");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
