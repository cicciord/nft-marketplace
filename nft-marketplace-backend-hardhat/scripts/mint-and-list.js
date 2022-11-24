const { ethers } = require("hardhat")

const PRICE = ethers.utils.parseEther("0.1")

async function mintAndList() {
    const marketplace = await ethers.getContract("Marketplace")
    const sampleNFTs = await ethers.getContract("SampleNFTs")

    console.log("Minting one NFT...")
    const mintTx = await sampleNFTs.mint()
    const mintTxReceipt = await mintTx.wait(1)
    console.log("NFT minted!")

    console.log("Approving marketplace...")
    const tokenId = mintTxReceipt.events[0].args.tokenId
    const approvalTx = await sampleNFTs.approve(marketplace.address, tokenId)
    await approvalTx.wait(1)
    console.log("Marketplace approved!")

    console.log("Listing NFT... ")
    const listTx = await marketplace.listItem(sampleNFTs.address, tokenId, PRICE)
    await listTx.wait(1)
    console.log("NFT listed... ")
}

mintAndList()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })
