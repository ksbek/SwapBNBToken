var TestToken = artifacts.require("./TestToken.sol");
var TokenSwap = artifacts.require("./TokenSwap.sol");
var SSTokenSwap = artifacts.require("./SSTokenSwap.sol");

module.exports = function(deployer, network) {
  if (network == "development") {
    deployer.deploy(TestToken, 'Test', 'TEST');
  }
  deployer.deploy(TokenSwap);
  deployer.deploy(SSTokenSwap);
};
