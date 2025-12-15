import { ethers } from "hardhat";

/**
 * Helper para gerar keccak256 de string UTF-8
 */
function keccakUtf8(s: string) {
  return ethers.keccak256(ethers.toUtf8Bytes(s));
}

async function main() {
  const [deployer] = await ethers.getSigners();

  const registryAddr = process.env.HORSE_REGISTRY!;
  if (!registryAddr) {
    throw new Error("Missing HORSE_REGISTRY in .env");
  }

  const registry = await ethers.getContractAt("HorseRegistry", registryAddr);

  /**
   * =========================
   * DADOS DO BANCO (Bruna)
   * =========================
   * Fonte: Registro oficial da Associação Brasileira dos Criadores
   */

  // PK do cavalo no seu banco (exemplo)
  const dbHorseId = 1;

  // Microchip (NUNCA vai em claro on-chain)
  const microchip = "982000362646702";

  /**
   * JSON canônico (ordem fixa, sem espaços desnecessários)
   * Isso representa a junção de:
   *  - cavalo
   *  - registro
   *  - mensuração
   *
   * Esse JSON é:
   *  - salvo no banco
   *  - opcionalmente salvo no IPFS
   *  - hash ancorado on-chain
   */
  const canonicalRegistroJson = JSON.stringify({
    cavalo: {
      nome: "Bruna do Muiraquitã",
      sexo: "FEMEA",
      data_nascimento: "2014-10-31",
      raca: "Campolina",
      microchip: "982000362646702",
    },
    registro: {
      tipo: "DEFINITIVO",
      numero_registro: "06/027361",
      situacao: "ATIVO",
      data_registro: "2014-10-31",
    },
    criacao: {
      criador: "Gustavo de Marco Turchetti",
      proprietario: "Gustavo de Marco Turchetti",
      haras: "Sítio Muiraquitã",
      cidade: "Nepomuceno",
      estado: "MG",
    },
    mensuracao: {
      pelagem: "LOBUNA",
      altura_cernelha_m: 1.52,
      comprimento_corpo_m: 1.54,
      perimetro_torax_m: 1.80,
      particularidades:
        "Espiga na borda ventral do pescoço (terço caudal). Rodopio na jugular lado direito cranial.",
      dna_confirmado: true,
      veterinario: "Paulo Sérgio de O. Marius - CRMV MG 3810",
    },
    genealogia: {
      pai: "Vulcano do Muiraquitã",
      mae: "Catarina BM",
    },
  });

  /**
   * =========================
   * HASHES (on-chain)
   * =========================
   */
  const microchipHash = keccakUtf8(microchip);
  const registroHash = keccakUtf8(canonicalRegistroJson);

  /**
   * =========================
   * TOKEN URI
   * =========================
   * Idealmente isso aponta para:
   *  - IPFS JSON (sem PII sensível)
   *  - ou API controlada pelo backend
   */
  const tokenURI =
    "ipfs://QmBRUNA_DO_MUIRAQUITA_METADATA_EXEMPLO";

  /**
   * =========================
   * MINT ON-CHAIN
   * =========================
   */
  const tx = await registry.mintHorseFromDb(
    deployer.address,
    dbHorseId,
    microchipHash,
    registroHash,
    tokenURI
  );

  const receipt = await tx.wait();

  const tokenId = await registry.tokenOfDbHorseId(dbHorseId);

  console.log("=================================");
  console.log("🐴 Cavalo mintado com sucesso!");
  console.log("Nome:", "Bruna do Muiraquitã");
  console.log("dbHorseId:", dbHorseId);
  console.log("tokenId:", tokenId.toString());
  console.log("tx hash:", receipt?.hash);
  console.log("=================================");
}

main().catch((e) => {
  console.error(e);
  process.exitCode = 1;
});
