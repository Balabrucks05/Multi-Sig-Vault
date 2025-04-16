const {ethers, upgrades} = require('hardhat');

async function main() {

    //Deploy
    // const [deployer] = ethers.getSigners();
    // console.log("Deploying the Contract with the account:", deployer.address);
   //Deploy the SparkoutToken Contract

    //Signer Address
    const signer1 = "0xde6541a09a4E8a9cBF7d8214B1AFf0e81880fF02";
    const signer2 = "0x321Ca5af7d80b6Db0D7D30E4A6c2b5b71D69FfE2";
    const signer3 = "0xAE1CA22AdFfD54b83937B5026De5e8aA43152A09";

    //Array of initial signers
    const initialSigners = [signer1,signer2,signer3];

    // //Number of required Approvals
    const requiredApprovals = 3;

    //Token Address
    const _tokenAddress = "0x6fe9c7Fb488840cF94d8A1F8Dfdc90004542Ea9E";

    //Deploy the MultiSigTokenVault Contract
    const MultiSigTokenVault = await ethers.getContractFactory("MultiSigTokenVault");

    const multiSigVault = await upgrades.deployProxy(MultiSigTokenVault,  [initialSigners, requiredApprovals, _tokenAddress],{ 
        initializer: "initialize",
        kind: "uups"
    });
    const MultiVaultTokenAddress = await multiSigVault.getAddress();

    console.log("MultiSigTokenVault deployed to:", MultiVaultTokenAddress );
    console.log("Signers used for deployment:", initialSigners);

    // //New MultiSigTokenVault instance using the factory
    // const MultiSigTokenVaultFactory = await ethers.getContractFactory("MultiSigTokenVaultFactory");
    // const vaultFactory = await upgrades.deployProxy(MultiSigTokenVaultFactory, [],{});
    // const vaultFactoryAddress = await vaultFactory.getAddress();
    // console.log("MultiSigTokenVaultFactory deployed to:", vaultFactoryAddress);

    // // Use the factory to create a new vault
    // const vaultAddress = await vaultFactory.createVault(initialSigners, requiredApprovals, _tokenAddress);

    // console.log("New Vault Address:", vaultAddress);

 }

main().catch((error) => {
    console.error(error);
    process.exit(1);
})