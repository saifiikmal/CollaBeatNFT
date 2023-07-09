const { abi } = require("../artifacts/contracts/CollaBeatUtility.sol/CollaBeatUtility.json")
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task("balance", "Prints an account's balance")
  .addParam("account", "The account's address")
  .setAction(async (taskArgs) => {
    const balance = await ethers.provider.getBalance(taskArgs.account);

    console.log(ethers.utils.formatEther(balance), "ETH");
  });

  task("fork", "Fork Collabeat NFT")
  .addOptionalParam("amount", "NFT amount")
  .setAction(async (taskArgs) => {
    const amount = parseInt(taskArgs.amount) || 1
    const mintFee = ethers.utils.parseUnits(process.env.MINT_PRICE, 'ether');

    const accounts = await ethers.getSigners();

    const provider = ethers.provider

    const contract = new ethers.Contract(process.env.UTILITY_CONTRACT, abi, provider)
    const utility = contract.connect(accounts[0])
    for (let i=0; i < amount; i++) {
      await utility.fork(`My Beat`, process.env.IPFS_ADDR, process.env.FORK_CID, { value: mintFee})
      console.log('Fork ', i)
    }
    // console.log('signer: ', accounts[0])
  });