const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("0x3Zero", function () {
  let erc721, erc721Factory, erc721Address

  before(async () => {
    const ERC721 = await ethers.getContractFactory("x3ZeroERC721");
    erc721 = await ERC721.deploy();
    await erc721.deployed();
    console.log('ERC721 Library: ', erc721.address)

    const ERC721Factory = await ethers.getContractFactory("x3ZeroERC721Factory");
    erc721Factory = await ERC721Factory.deploy(erc721.address)
    await erc721Factory.deployed();
    console.log('ERC721 Factory: ', erc721Factory.address)

    await erc721Factory.createNFT('Collabeat', 'COLLABEAT')
    erc721Address = await erc721Factory.getLatestNFT()
    // console.log(nftAddress)
    console.log('ERC721 Address: ', erc721Address)
  })
})