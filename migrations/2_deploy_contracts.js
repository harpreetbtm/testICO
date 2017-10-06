//var ConvertLib = artifacts.require("./ConvertLib.sol");
//var MetaCoin = artifacts.require("./MetaCoin.sol");
var ArrayUtil=artifacts.require("./ArrayUtil.sol")
var AssetCoin=artifacts.require("./OdinCoin.sol");
var AssetCoinSale=artifacts.require("./OdinCoinSale.sol");
var DividendManager=artifacts.require("./DividendManager.sol")

module.exports = function(deployer,network,accounts) {
  const RS=web3.eth.accounts[0];
  const CS=web3.eth.accounts[0];
  const MS=web3.eth.accounts[2];
  const SW=web3.eth.accounts[4];

  var meta;
  //d;
  /*
  AssetCoin.deployed().then(function(instance){
                              hello=instance;
                              console.log(hello.address);
                              var ACT=hello.address;
                              deployer.deploy(AssetCoinSale,CS,ACT,MS,RS,1)});

  */

/*
  AssetCoin.deployed().then(function(instance){

            // hello=instance;
            meta=instance;
            console.log('Address for coin is : ' + meta.address)
             //meta=hello.address;
  });
  console.log('Address forrrrrrr coin is : ' + meta);
  console.log(meta);

*/
/*
deployer.deploy(AssetCoin,RS).then(function(){
             var meta;
             meta=AssetCoin.deployed();
             return meta;
}).then(function(instance){
             var AST=instance.address;
             console.log("Address for coin is :"+instance.address);
             return AST;
}).then(function(assetadd){
             console.log("Going to deploy Crowdsale contract");
             console.log("Address is going to be :" + assetadd);
             deployer.deploy(AssetCoinSale,CS,assetadd,MS,RS,1);
             return AssetCoinSale.deployed();
}).then(function(instance){
             console.log("Address for sale contract is :" + instance.address);
});
*/

/*
//deployer.deploy(ArrayUtil);
//deployer.link(ArrayUtil,AssetCoin);
deployer.deploy(AssetCoin,RS).then(function(instance){
        meta=instance;
        add=AssetCoin.address;
        return deployer.deploy(AssetCoinSale,CS,add,MS,RS,1);
});

*/


deployer.deploy(ArrayUtil).then(function(instance){
         return deployer.link(ArrayUtil,AssetCoin);
}).then(function(instance){
         return deployer.deploy(AssetCoin,RS);
}).then(function(instance){
        return deployer.deploy(DividendManager,AssetCoin.address);
}).then (function(instance){
         meta=instance;
         add=AssetCoin.address;
         return deployer.deploy(AssetCoinSale,CS,add,MS,RS,SW);
});



/* Final working model which is not sensible
deployer.deploy(AssetCoin,RS).then(function(instance){
        return deployer.deploy(AssetCoinSale,CS,AssetCoin.address,MS,RS,SW);
})

*/
  /*
  var meta;
  deployer.deploy(AssetCoin,RS);
  AssetCoin.deployed().then(function(instance){meta=instance;});
  deployer.deploy(AssetCoinSale,CS,meta.address,MS,RS,1);
*/

};
