const { network } = require("hardhat")
const { developmentChains, testChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    if (developmentChains.includes(network.name) || testChains.includes(network.name)) {
        const { deploy, log } = deployments
        const { deployer } = await getNamedAccounts()

        log("--------------------------------------------------")
        let args = []

        const sampleNFTs = await deploy("SampleNFTs", {
            from: deployer,
            args: args,
            log: true,
            waitConfirmations: network.config.blockConfirmations || 1,
        })

        if (!developmentChains.includes(network.name) && process.env.ETHERSCAN_API_KEY) {
            log("Verifying contract on etherscan...")
            await verify(sampleNFTs.address, args)
        }

        log("--------------------------------------------------")
    }
}

module.exports.tags = ["all", "nfts"]
