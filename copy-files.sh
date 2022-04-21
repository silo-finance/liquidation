#!/bin/bash

rm ./LICENSE*
rm -rf ./cache
rm -rf ./artifacts
rm -rf ./contracts
rm -rf ./deployments

mkdir -p "contracts/liquidation"
mkdir -p "contracts/interfaces"
mkdir -p "contracts/lib"
mkdir -p "deployments/kovan"
mkdir -p "deployments/rinkeby"
mkdir -p "deployments/goerli"


cd ../silo-contracts/

npx hardhat compile

cp ./LICENSE* ../liquidation/
cp -R ./contracts/liquidation/* ../liquidation/contracts/liquidation/
cp -R ./deployments/kovan/* ../liquidation/deployments/kovan/
cp -R ./deployments/rinkeby/* ../liquidation/deployments/rinkeby/
cp -R ./deployments/goerli/* ../liquidation/deployments/goerli/

find ../liquidation/deployments/ -type f -name "Founding*" -depth -delete;
find ../liquidation/deployments/ -type f -name "Funders*" -depth -delete;
find ../liquidation/deployments/ -type f -name "Future*" -depth -delete;
find ../liquidation/deployments/ -type f -name "SiloDAO*" -depth -delete;
find ../liquidation/deployments/ -type f -name "SiloGov*" -depth -delete;
find ../liquidation/deployments/ -type f -name "SiloSnap*" -depth -delete;
find ../liquidation/deployments/ -type f -name "Time*" -depth -delete;
find ../liquidation/deployments/ -type f -name "TreasuryVester*" -depth -delete;

cp ./contracts/lib/EasyMath.sol ../liquidation/contracts/lib/
cp ./contracts/lib//ModelStats.sol ../liquidation/contracts/lib/
cp ./contracts/lib/Ping.sol ../liquidation/contracts/lib/
cp ./contracts/lib/Solvency.sol ../liquidation/contracts/lib/

cp ./contracts/Error.sol ../liquidation/contracts/
cp ./contracts/SiloLens.sol ../liquidation/contracts/

cp ./contracts/interfaces/IBaseSilo.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IFlashLiquidationReceiver.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IInterestRateModel.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/INotificationReceiver.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IPriceProvider.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IPriceProvidersRepository.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/IShareToken.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/ISilo.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/ISiloFactory.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/ISiloRepository.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/ISwapper.sol ../liquidation/contracts/interfaces/
cp ./contracts/interfaces/ITokensFactory.sol ../liquidation/contracts/interfaces/

cd -

npx hardhat compile

find ./artifacts/ -type f -name "*.dbg.json" -depth -delete;

echo "DONE :)"
