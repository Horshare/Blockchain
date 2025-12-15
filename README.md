# 🐴 Horshare — Blockchain Layer (Scroll)

Este repositório contém a **implementação on-chain do projeto Horshare**, responsável pelo **registro e tokenização de cavalos** utilizando contratos inteligentes na rede **Scroll Sepolia (EVM)**.

Nesta etapa, foi implementado e validado um **MVP funcional** que permite:

* Registrar cavalos como **NFTs (ERC-721)**
* Ancorar registros oficiais e mensurações de forma criptográfica
* Garantir unicidade por **ID de banco** e **microchip**
* Criar **cotas fracionárias (ERC-20)** associadas a cada cavalo
* Executar todo o fluxo em testnet (deploy → mint → tokenização)

---

## 📐 Visão Geral da Arquitetura

A arquitetura segue o princípio de **separação entre identidade e valor econômico**:

| Camada                 | Representação             |
| ---------------------- | ------------------------- |
| Identidade do cavalo   | NFT (ERC-721)             |
| Participação econômica | Token ERC-20 (cotas)      |
| Dados completos        | Banco de dados + IPFS     |
| Prova de integridade   | Hashes ancorados on-chain |

---

## Contratos Inteligentes

###  HorseRegistry (`ERC-721`)

Contrato responsável por **registrar cavalos como NFTs**.

Cada NFT representa **um cavalo único**, vinculado ao banco de dados e ao registro oficial.

#### Responsabilidades

* Mint de cavalo a partir do banco (`mintHorseFromDb`)
* Garantia de unicidade:

  * `dbHorseId` (PK do banco)
  * `microchipHash` (hash do microchip)
* Armazenar:

  * `dbHorseId`
  * `microchipHash`
  * `latestRegistroHash`
* Atualizar registro (ex.: provisório → definitivo)
* Pausar transferências em caso de emergência

#### Dados **não** armazenados on-chain

* CPF
* Endereço
* Documentos pessoais
* Dados sensíveis (PII)

Esses dados permanecem **off-chain**, sendo apenas **ancorados criptograficamente**.

---

###  HorseSharesFactory

Contrato **orquestrador** responsável por criar tokens de cotas.

#### Responsabilidades

* Criar um ERC-20 **por cavalo**
* Garantir que:

  * Apenas o **dono do NFT** pode criar cotas
  * Um cavalo só pode ser tokenizado **uma vez**
* Mapear:

  * `horseTokenId → shareToken`
  * `dbHorseId → shareToken`

---

### HorseShareToken (`ERC-20`)

Contrato que representa as **cotas fracionárias** de um cavalo.

#### Características

* Um contrato ERC-20 por cavalo
* Supply definida no momento da criação
* Mint controlado pela Factory
* Suporte a:

  * `pause / unpause` (compliance)
* Totalmente compatível com DEXs EVM

---

## Rede Utilizada

* **Rede:** Scroll Sepolia (testnet)
* **Chain ID:** `534351`
* **RPC:** `https://sepolia-rpc.scroll.io`
* **Explorer:** [https://sepolia.scrollscan.com](https://sepolia.scrollscan.com)

---

## Setup do Projeto

### Pré-requisitos

* Node.js `>= 18`
* NPM
* Wallet EVM (MetaMask ou Rabby)
* ETH na **Scroll Sepolia**

---

### Instalação

```bash
npm install
```

---

### Variáveis de Ambiente (`.env`)

```env
PRIVATE_KEY=0xSUA_PRIVATE_KEY
SCROLL_SEPOLIA_RPC=https://sepolia-rpc.scroll.io

HORSE_REGISTRY=0x...
SHARES_FACTORY=0x...
HORSE_TOKEN_ID=1
```

> Nunca commite o `.env`

---

## Compilação

```bash
npx hardhat compile
```

Resultado esperado:

```
Compiled XX Solidity files successfully
```

---

## Deploy dos Contratos

```bash
npx hardhat run scripts/deploy.ts --network scrollSepolia
```

### Endereços gerados (exemplo real)

* **HorseRegistry:**
  `0x4f7dBB2F9353Bfdd95BD153912405c2559Bb6A3B`

* **HorseSharesFactory:**
  `0x1223aFa91995e88a838c0080c8fd9414C808c815`

---

## Mint do Cavalo (NFT)

Foi realizado o mint do cavalo **Bruna do Muiraquitã**, com base em registro oficial real.

### Script

```bash
npx hardhat run scripts/mintBruna.ts --network scrollSepolia
```

### O que o script faz

* Normaliza os dados do cavalo
* Gera:

  * `microchipHash`
  * `registroHash`
* Minta o NFT via `mintHorseFromDb`
* Associa o NFT ao dono (smart account)

### Resultado

* **Token ID:** `1`
* **Owner:** wallet do deployer
* **Tx:** confirmada no Scrollscan

---

## Dados Ancorados On-chain

| Campo                | Origem                                        |
| -------------------- | --------------------------------------------- |
| `dbHorseId`          | PK da tabela `cavalo`                         |
| `microchipHash`      | hash do microchip                             |
| `latestRegistroHash` | hash do JSON canônico (registro + mensuração) |
| `tokenURI`           | IPFS / backend                                |

---

## Criação de Cotas (ERC-20)

Após o mint do cavalo:

```bash
npx hardhat run scripts/createShares.ts --network scrollSepolia
```

### Exemplo

* Cavalo: Bruna do Muiraquitã
* Supply: `1000` cotas
* Símbolo: `BRUNA`

Resultado:

* Um novo contrato ERC-20 é criado
* Supply mintada para o dono do cavalo
* Token visível no explorer

---

## Verificação e Debug

### Console Hardhat

```bash
npx hardhat console --network scrollSepolia
```

```js
const registry = await ethers.getContractAt("HorseRegistry", "<ADDR>");
await registry.ownerOf(1);
await registry.tokenURI(1);
await registry.latestRegistroHashOfToken(1);
```

---

## Segurança e Boas Práticas

* Sem PII on-chain
* Hashes para integridade
* Unicidade garantida por mappings
* Pausable em todos os contratos críticos
* Arquitetura preparada para multichain

