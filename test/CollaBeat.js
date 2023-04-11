const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CollaBeat", function () {
  let creator, owner1, owner2;
  let nft, utility;
  let tokenURI = 'http://localhost/metadata/'
  const cid = "bafyreiegymvctsxcgew6ccqvrjatx6j32nmbe76co576ow7zltuswyyf7y"

  const mintFee = ethers.utils.parseUnits('0.05', 'ether');
  const collabFee = ethers.utils.parseUnits('0.05', 'ether');

  before(async () => {
    ([creator, owner1, owner2, owner3] = await ethers.getSigners());

    const NFT  = await ethers.getContractFactory('CollaBeatNFT');
    nft = await NFT.deploy(tokenURI);
    await nft.deployed();
    console.log('LeMusicNFT: ', nft.address)

    const UTILITY = await ethers.getContractFactory('CollaBeatUtility');
    utility = await UTILITY.deploy(nft.address, mintFee, owner1.address, 0, "0");
    await utility.deployed();
    console.log('LeMusicUtility: ', utility.address)

    // grant minter role
    const minterRole = await nft.MINTER_ROLE()
    const uriSetterRole = await nft.URI_SETTER_ROLE()
    // console.log({minterRole})
    await nft.grantRole(minterRole, utility.address)
    await nft.grantRole(uriSetterRole, utility.address)
  });

  it("Fork", async function () {
    const hash = nft.address.toLowerCase()+"1"+"0"+"0"
    const hashByte = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(hash))
    const hashUri = tokenURI+hashByte.substring(2)

    const abi = ethers.utils.defaultAbiCoder;
    const eventData = abi.encode(
      ["string", "string"],
      [hashByte.substring(2), cid]
    )

    console.log({hash, hashUri, hashByte})
    console.log(abi.decode(["string", "string"], eventData))

    utility = utility.connect(owner1)
    await expect(utility.fork(cid, {
      value: mintFee,
      //gasLimit: 3000000
    }))
    .to.emit(utility, 'Forked').withArgs(owner1.address, 1, hashByte.substring(2), cid)
    .to.emit(nft, 'Minted').withArgs(owner1.address, 1, eventData);


    const balance = await nft.balanceOf(owner1.address, 1)
    expect(balance).to.equal(1)

    const totalSupply = await nft.totalSupply(1)
    expect(totalSupply).to.equal(1)

    const currentTokenId = await nft.currentTokenId()
    expect(currentTokenId).to.equal(1)

    const uri = await nft.uri(1)
    expect(uri).to.equal(hashUri)
    
  });

  it("Mint", async function () {

    utility = utility.connect(owner2)
    await expect(utility.mint(1, 1, {
      value: mintFee,
      //gasLimit: 3000000
    }))
    .to.emit(utility, 'Minted').withArgs(owner2.address, 1, 1)
    .to.emit(nft, 'Minted').withArgs(owner2.address, 1, "0x");

    const balance = await nft.balanceOf(owner2.address, 1)
    expect(balance).to.equal(1)
  });

  it("Fork2", async function () {
    const hash = nft.address.toLowerCase()+"2"+"0"+"0"
    const hashByte = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(hash))
    const hashUri = tokenURI+hashByte.substring(2)

    const abi = ethers.utils.defaultAbiCoder;
    const eventData = abi.encode(
      ["string", "string"],
      [hashByte.substring(2), cid]
    )

    console.log({hash, hashUri, hashByte})

    utility = utility.connect(owner3)
    await expect(utility.fork(cid, {
      value: mintFee,
      //gasLimit: 3000000
    }))
    .to.emit(utility, 'Forked').withArgs(owner3.address, 2, hashByte.substring(2), cid)
    .to.emit(nft, 'Minted').withArgs(owner3.address, 2, eventData);

    const balance = await nft.balanceOf(owner3.address, 2)
    expect(balance).to.equal(1)

    const totalSupply = await nft.totalSupply(2)
    expect(totalSupply).to.equal(1)

    const currentTokenId = await nft.currentTokenId()
    expect(currentTokenId).to.equal(2)

    const uri = await nft.uri(2)
    expect(uri).to.equal(hashUri)
    
  });

});