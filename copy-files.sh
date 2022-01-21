#!/bin/bash

rm -rf ./cache
rm -rf ./artifacts
rm -rf ./contracts
rm -rf ./deployments

mkdir -p "contracts/liquidation"
mkdir -p "contracts/interfaces"
mkdir -p "contracts/lib"
mkdir -p "deployments/kovan"
mkdir -p "deployments/rinkeby"


cd ../silo-contracts/

npx hardhat compile

cp ./LICENSE ../liquidation/
cp -R ./contracts/liquidation/* ../liquidation/contracts/liquidation/
cp -R ./deployments/kovan/* ../liquidation/deployments/kovan/
cp -R ./deployments/rinkeby/* ../liquidation/deployments/rinkeby/

find ../liquidation/deployments/ -type f -name "Founding*" -depth -delete;
find ../liquidation/deployments/ -type f -name "Funders*" -depth -delete;
find ../liquidation/deployments/ -type f -name "Future*" -depth -delete;
find ../liquidation/deployments/ -type f -name "SiloDAO*" -depth -delete;
find ../liquidation/deployments/ -type f -name "SiloGov*" -depth -delete;
find ../liquidation/deployments/ -type f -name "SiloSnap*" -depth -delete;
find ../liquidation/deployments/ -type f -name "Time*" -depth -delete;
find ../liquidation/deployments/ -type f -name "TreasuryVester*" -depth -delete;

cp ./contracts/SiloLens.sol ../liquidation/contracts/
cp ./contracts/lib/EasyMath.sol ../liquidation/contracts/lib/

cp ./contracts/interfaces/IFlashLiquidationReceiver.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IFactory.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IOracle.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IBaseSilo.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/ISilo.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/ISwapper.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IRepository.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IShareToken.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/ISiloOracleRepository.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/ITokensFactory.sol ../liquidation/contracts/interfaces/

cd -

npx hardhat compile


echo "DONE :)"
