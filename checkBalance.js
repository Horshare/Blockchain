require('dotenv').config();
const { ethers } = require("ethers");

async function main() {
  const provider = new ethers.JsonRpcProvider("https://sepolia-rpc.scroll.io");
  const privateKey = "0x" + process.env.PRIVATE_KEY;
  const wallet = new ethers.Wallet(privateKey, provider);
  
  console.log("\n💰 Saldo da carteira do backend:");
  console.log("Endereço:", wallet.address);
  
  const balance = await provider.getBalance(wallet.address);
  const balanceInEth = ethers.formatEther(balance);
  
  console.log("Saldo:", balanceInEth, "ETH");
  
  if (parseFloat(balanceInEth) < 0.001) {
    console.log("\n⚠️  AVISO: Saldo muito baixo ou zero!");
    console.log("A carteira precisa de ETH na Scroll Sepolia para pagar gas das transações.");
    console.log("\n📝 Para obter ETH de teste na Scroll Sepolia:");
    console.log("1. Acesse o faucet: https://docs.scroll.io/en/user-guide/faucet/");
    console.log("2. Ou faça bridge de Sepolia ETH: https://scroll.io/portal/bridge");
    console.log("3. Endereço para receber:", wallet.address);
  } else {
    console.log("✅ Saldo suficiente para transações!");
  }
}

main().catch(console.error);
