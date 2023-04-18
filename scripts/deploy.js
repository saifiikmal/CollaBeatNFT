// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
const hre = require("hardhat");

async function main() {
  const price = hre.ethers.utils.parseUnits(process.env.MINT_PRICE, 'ether')

  const NFT = await hre.ethers.getContractFactory("CollaBeatNFT");
  const nft = await NFT.deploy(process.env.TOKEN_BASE_URI)
  await nft.deployed();

  console.log('collabeatnft: ', nft.address)

  const Utility =  await hre.ethers.getContractFactory("CollaBeatUtility")
  const utility = await Utility.deploy(nft.address, price, process.env.FEE_RECEIVER, process.env.NONCE, process.env.CHAIN_ID)
  await utility.deployed()
  
  console.log("collabeatutility: ", utility.address)

  // grant minter role
  const minterRole = await nft.MINTER_ROLE()
  const uriSetterRole = await nft.URI_SETTER_ROLE()
  // console.log({minterRole})
  await nft.grantRole(minterRole, utility.address)
  await nft.grantRole(uriSetterRole, utility.address)
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});