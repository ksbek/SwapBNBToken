var TestToken = artifacts.require("./TestToken.sol");
var SSTokenSwap = artifacts.require("./SSTokenSwap.sol");

contract('SSTokenSwap', function (accounts) {
  var token, tokenIn, amountIn, ts;

  var buyer = accounts[0];
  var seller = accounts[1];
  var owner = accounts[2];

  var amount = 150;

  var startedTime = Math.floor(Date.now() / 1000) - 3600 * 1; // Swap started 2 hours ago
  var bonusRatio = 20;


  beforeEach(function () {
    return TestToken.new('Test1', 'test', { from: seller }).then(function (newToken) {
      token = newToken;
      return TestToken.new('Test2', 'test2', { from: buyer })
    }).then(function (newToken) {
      tokenIn = newToken;
      var now = Math.floor(Date.now() / 1000);
      console.log(now);
      var hoursPassed = Math.floor((now - startedTime) / 3600);
      console.log(hoursPassed);
      amountIn = Math.floor(amount + amount * (bonusRatio / (hoursPassed + 1)) / 100);
      console.log(amountIn);
      return SSTokenSwap.new(startedTime, bonusRatio, { from: owner });
    }).then(function (newSSTokenSwap) {
      ts = newSSTokenSwap;
    });
  });

  it("seller should have tokens", function () {
    return token.totalSupply().then(function (supply) {
      return token.balanceOf(seller).then(function (balance) {
        assert.equal(BigInt(supply), BigInt(balance));
      });
    });
  });

  // it("buyer should have tokens", function() {
  //   return tokenIn.totalSupply().then(function(supply) {
  //     return tokenIn.balanceOf(buyer).then(function(balance) {
  //       assert.equal(BigInt(supply), BigInt(balance));
  //     });
  //   });
  // });

  it("user can create new Swap", function () {
    return ts.create(token.address, amount, tokenIn.address, seller, buyer, { from: buyer });
  });

  it("seller can approve SSTokenSwap contract", function () {
    return ts.create(token.address, amount, tokenIn.address, seller, buyer, { from: buyer })
      .then(function (events) {
        return token.approve(ts.address, amount, { from: seller });
      });
  });

  it("buyer can send tokenIn to SSTokenSwap contract", function () {
    return ts.create(token.address, amount, tokenIn.address, seller, buyer, { from: buyer })
      .then(function () {
        return token.approve(ts.address, amount, { from: seller });
      }).then(function () {
        return tokenIn.approve(ts.address, amountIn, { from: buyer });
      }).then(function () {
        return ts.conclude({ from: buyer, value: amountIn });
      });
  });

  it("buyer should have correct amount of tokens", function () {
    return ts.create(token.address, amount, tokenIn.address, seller, buyer, { from: buyer })
      .then(function () {
        return token.approve(ts.address, amount, { from: seller });
      }).then(function () {
        return tokenIn.approve(ts.address, amountIn, { from: buyer });
      }).then(function () {
        return ts.conclude({ from: buyer, value: amountIn });
      }).then(function () {
        return token.balanceOf.call(buyer);
      }).then(function (balance) {
        return assert.equal(amount, BigInt(balance));
      });
  });

  it("seller should have correct amount of tokenIn", function () {
    var oldBalance, newBalance;

    return ts.create(token.address, amount, tokenIn.address, seller, buyer, { from: buyer })
      .then(function () {
        return token.approve(ts.address, amount, { from: seller });
      }).then(function () {
        return tokenIn.approve(ts.address, amountIn, { from: buyer });
      }).then(function () {
        return ts.conclude({ from: buyer, value: amountIn });
      }).then(function () {
        return tokenIn.balanceOf.call(seller);
      }).then(function (balance) {
        return assert.equal(amountIn, BigInt(balance));
      });
  });
});
