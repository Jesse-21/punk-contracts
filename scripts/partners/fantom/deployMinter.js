// npx hardhat run scripts/partners/fantom/deployMinter.js --network opera
// add minter address to:
// 1) TLD contract as minter

const contractNameFactory = "FantomMinter";

const brokerAddress = "0x5d0af5a949d65bc9e8c2f8be252f7d0f76816a00";
const pgfAddress = "0xb21b972B2aA69a01C6f7e6C19717126C7cD7559F";
const tldAddress = "0xBDACF94dDCAB51c39c2dD50BffEe60Bb8021949a";

const paymentTokenDecimals = 18;

const price1char = ethers.utils.parseUnits("5000", paymentTokenDecimals);
const price2char = ethers.utils.parseUnits("2500", paymentTokenDecimals);
const price3char = ethers.utils.parseUnits("779", paymentTokenDecimals);
const price4char = ethers.utils.parseUnits("129", paymentTokenDecimals);
const price5char = ethers.utils.parseUnits("49", paymentTokenDecimals);

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // deploy contract
  const contract = await ethers.getContractFactory(contractNameFactory);
  const instance = await contract.deploy(
    brokerAddress, pgfAddress, tldAddress, 
    price1char, price2char, price3char, price4char, price5char
  );
  
  console.log("Contract address:", instance.address);

  console.log("Wait a minute and then run this command to verify contract on the block explorer:");
  console.log("npx hardhat verify --network " + network.name + " " + instance.address + " " + brokerAddress + " " + pgfAddress + " " + tldAddress + ' "' + price1char + '" "' + price2char + '" "' + price3char + '" "' + price4char + '" "' + price5char + '"');
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });