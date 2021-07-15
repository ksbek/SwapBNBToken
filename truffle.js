module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    live: {
      network_id: 1, // BSC public network
    }
  },
  compilers: {
    solc: {
      version: "0.8.6",
    },
  },
};
