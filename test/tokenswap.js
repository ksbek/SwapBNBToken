var TestToken = artifacts.require("./TestToken.sol");
var TokenSwap = artifacts.require("./TokenSwap.sol");

contract('TokenSwap', function(accounts) {
  var token, ts;

  var buyer = accounts[0];
  var seller = accounts[1];
  var owner = accounts[2];

  var price = 10000000;
  var amount = 150;


  beforeEach(function() {
    return TestToken.new('test', 'test', {from: seller}).then(function(newToken) {
      token = newToken;
      return TokenSwap.new({from: owner});
    }).then(function(newTokenSwap) {
      ts = newTokenSwap;
    });
  });

  it("seller should have tokens", function() {
    return token.totalSupply().then(function(supply) {
      return token.balanceOf(seller).then(function(balance) {
        assert.equal(BigInt(supply), BigInt(balance));
      });
    });
  });

  it("user can create new Swap", function() {
    return ts.create(token.address, amount, price, seller, buyer, {from: buyer});
  });

  it("seller can approve TokenSwap contract", function() {
    return ts.create(token.address, amount, price, seller, buyer, {from: buyer})
    .then(function(events) {
      return token.approve(ts.address, amount, {from: seller});
    });

    // TODO: test for Approval event
  });

  it("buyer can send BNB to TokenSwap contract", function() {
    return ts.create(token.address, amount, price, seller, buyer, {from: buyer})
    .then(function() {
      return token.approve(ts.address, amount, {from: seller});
    }).then(function() {
      return ts.conclude({from: buyer, value: price});
    });
  });

  it("buyer should have correct amount of tokens", function() {
    return ts.create(token.address, amount, price, seller, buyer, {from: buyer})
    .then(function() {
      return token.approve(ts.address, amount, {from: seller});
    }).then(function() {
      return ts.conclude({from: buyer, value: price});
    }).then(function() {
      return token.balanceOf.call(buyer);
    }).then(function(balance) {
      return assert.equal(amount, BigInt(balance));
    });
  });

  it("seller should have correct amount of BNB", function() {
    var oldBalance, newBalance;

    return ts.create(token.address, amount, price, seller, buyer, {from: buyer})
    .then(function() {
      return token.approve(ts.address, amount, {from: seller});
    }).then(async function() {
      oldBalance = await web3.eth.getBalance(seller);
      return ts.conclude({from: buyer, value: price});
    }).then(async function(res) {
      newBalance = await web3.eth.getBalance(seller);
      return assert.equal(BigInt(oldBalance) + BigInt(price), BigInt(newBalance));
    });
  });
});
