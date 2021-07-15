var TestToken = artifacts.require("./TestToken.sol");
var TokenSwap = artifacts.require("./TokenSwap.sol");

module.exports = function(deployer, network) {
  if (network == "development") {
    deployer.deploy(TestToken, 'Test', 'TEST');
  }
  deployer.deploy(TokenSwap);
};
