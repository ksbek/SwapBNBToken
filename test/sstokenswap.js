var TestToken = artifacts.require("./TestToken.sol");
var SSTokenSwap = artifacts.require("./SSTokenSwap.sol");

contract('SSTokenSwap', function (accounts) {
  var token1, token2, ts;

  var buyer = accounts[0];
  var seller = accounts[1];
  var owner = accounts[2];

  var price = 10000000;
  var amount1 = 150;
  var amount2 = 150;


  beforeEach(function () {
    return TestToken.new('Test1', 'test', { from: seller }).then(function (newToken) {
      token1 = newToken;
      return TestToken.new('Test2', 'test2', { from: buyer })
    }).then(function (newToken) {
      token2 = newToken;
      return SSTokenSwap.new({ from: owner });
    }).then(function (newSSTokenSwap) {
      ts = newSSTokenSwap;
    });
  });

  it("seller should have tokens", function () {
    return token1.totalSupply().then(function (supply) {
      return token1.balanceOf(seller).then(function (balance) {
        assert.equal(BigInt(supply), BigInt(balance));
      });
    });
  });

  // it("buyer should have tokens", function() {
  //   return token2.totalSupply().then(function(supply) {
  //     return token2.balanceOf(buyer).then(function(balance) {
  //       assert.equal(BigInt(supply), BigInt(balance));
  //     });
  //   });
  // });

  it("user can create new Swap", function () {
    return ts.create(token1.address, amount1, token2.address, amount2, seller, buyer, { from: buyer });
  });

  it("seller can approve SSTokenSwap contract", function () {
    return ts.create(token1.address, amount1, token2.address, amount2, seller, buyer, { from: buyer })
      .then(function (events) {
        return token1.approve(ts.address, amount1, { from: seller });
      });
  });

  it("buyer can send token2 to SSTokenSwap contract", function () {
    return ts.create(token1.address, amount1, token2.address, amount2, seller, buyer, { from: buyer })
      .then(function () {
        return token1.approve(ts.address, amount1, { from: seller });
      }).then(function () {
        return token2.approve(ts.address, amount2, { from: buyer });
      }).then(function () {
        return ts.conclude({ from: buyer, value: amount2 });
      });
  });

  it("buyer should have correct amount of tokens", function () {
    return ts.create(token1.address, amount1, token2.address, amount2, seller, buyer, { from: buyer })
      .then(function () {
        return token1.approve(ts.address, amount1, { from: seller });
      }).then(function () {
        return token2.approve(ts.address, amount2, { from: buyer });
      }).then(function () {
        return ts.conclude({ from: buyer, value: amount2 });
      }).then(function () {
        return token1.balanceOf.call(buyer);
      }).then(function (balance) {
        return assert.equal(amount1, BigInt(balance));
      });
  });

  it("seller should have correct amount of token2", function () {
    var oldBalance, newBalance;

    return ts.create(token1.address, amount1, token2.address, amount2, seller, buyer, { from: buyer })
      .then(function () {
        return token1.approve(ts.address, amount1, { from: seller });
      }).then(function () {
        return token2.approve(ts.address, amount2, { from: buyer });
      }).then(function () {
        return ts.conclude({ from: buyer, value: amount2 });
      }).then(function () {
        return token2.balanceOf.call(seller);
      }).then(function (balance) {
        return assert.equal(amount2, BigInt(balance));
      });
  });
});
