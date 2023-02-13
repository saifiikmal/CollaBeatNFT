const { expect } = require("chai");

describe("LeMusic", function () {
  let creator, owner1, owner2;
  let nft, utility;
  let tokenURI = 'http://localhost/metadata.json'

  const mintFee = ethers.utils.parseUnits('0.05', 'ether');
  const collabFee = ethers.utils.parseUnits('0.05', 'ether');

  before(async () => {
    ([creator, owner1, owner2] = await ethers.getSigners());

    const NFT  = await ethers.getContractFactory('LeMusicNFT');
    nft = await NFT.deploy();
    await nft.deployed();
    console.log('LeMusicNFT: ', nft.address)

    const UTILITY = await ethers.getContractFactory('LeMusicUtility');
    utility = await UTILITY.deploy(nft.address, mintFee, collabFee, owner1.address);
    await utility.deployed();
    console.log('LeMusicUtility: ', utility.address)

    // grant minter role
    const minterRole = await nft.MINTER_ROLE()
    // console.log({minterRole})
    await nft.grantRole(minterRole, utility.address)

  });

  it("Mint", async function () {
    utility = utility.connect(owner1)
    await expect(utility.mint(1, tokenURI, {
      value: mintFee,
      //gasLimit: 3000000
    })).to.emit(utility, 'Minted').withArgs(owner1.address, 1, tokenURI);

    const balance = await nft.balanceOf(owner1.address, 1)
    expect(balance).to.equal(1)
  });

  it("Collab", async function () {
    utility = utility.connect(owner2)
    await expect(utility.collab(1, 1, {
      value: collabFee,
      //gasLimit: 3000000
    })).to.emit(utility, 'Collab').withArgs(owner2.address, 1, 1);

    const balance = await nft.balanceOf(owner2.address, 1)
    expect(balance).to.equal(1)

    const totalSupply = await nft.totalSupply(1)
    expect(totalSupply).to.equal(2)
  });
});