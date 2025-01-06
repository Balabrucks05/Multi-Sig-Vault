const {ethers, upgrades} = require('hardhat');

async function main() {
    // const [deployer] = ethers.getSigners();
    // console.log("Deploying the Contract with the account:", deployer.address);
    //Deploy the SparkoutToken Contract

    // const SparkoutToken = await ethers.getContractFactory("SparkoutToken");
    // const initialSupply = ethers.parseUnits("50000000000", 18); //500 Billion
    // const sparkToken = await upgrades.deployProxy(SparkoutToken,[initialSupply],{ 
    //     initializer: "initialize",
    //     kind: "uups"
    // });
    // const SparkTokenAddress = await sparkToken.getAddress();

    // console.log("Sparkout Token Contract Deployed to:", SparkTokenAddress)

    //Signer Address
    const signer1 = "0xF6D3FAcd79284E64eaB547BeE31Db9e2C1663eE7";
    const signer2 = "0xdDE0D25b44f2047481e0eE7F9fB13e6137733334";
    const signer3 = "0x6EB1EED61F47D16598D4B017D05e400C0a20E6E6";

    //Array of initial signers
    const initialSigners = [signer1,signer2,signer3];

    //Number of required Approvals
    const requiredApprovals = 3;

    //Token Address
    const _tokenAddress = "0xF027effd400A3dA01a9571b02e192d0B7daB626a";

    //Deploy the MultiSigTokenVault Contract
    const MultiSigTokenVault = await ethers.getContractFactory("MultiSigTokenVault");

    const multiSigVault = await upgrades.deployProxy(MultiSigTokenVault,  [initialSigners, requiredApprovals, _tokenAddress],{ 
        initializer: "initialize",
        kind: "uups"
    });
    const MultiVaultTokenAddress = await multiSigVault.getAddress();

    console.log("MultiSigTokenVault deployed to:", MultiVaultTokenAddress );
    console.log("Signers used for deployment:", initialSigners);

}

main().catch((error) => {
    console.error(error);
    process.exit(1);
})