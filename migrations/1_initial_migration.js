const { BigNumber } = require("@ethersproject/bignumber");
const { deployProxy, upgradeProxy } = require("@openzeppelin/truffle-upgrades");
const Referral = artifacts.require("Referral");
const MONSTER_TOKEN = "0x23040c7b54112a6E6e70559d49114Ed80C41C282";

module.exports = async function (deployer) {
  console.log("Start Deployment Here");
  const Proxy_Referral = await deployProxy(Referral, [MONSTER_TOKEN], {
    deployer,
    initializer: "initialize",
  });
  console.log("--Complete --");
  console.log("Deployed Referral", Proxy_Referral.address);

  const Current_Referral = await Referral.deployed();
  // const Upgraded_Referral = await upgradeProxy(
  //   Current_Referral.address,
  //   ReferralV2,
  //   {
  //     deployer,
  //   }
  // );
  // console.log("--Complete --");
  // console.log("Upgraded Referral", Upgraded_Referral.address);
};
