import '@nomiclabs/hardhat-ethers';
import {HardhatUserConfig} from 'hardhat/types';

const config: HardhatUserConfig = {
  defaultNetwork: 'hardhat',
  solidity: {
    compilers: [
      {
        version: '0.8.7',
        settings: {}
      },
      {
        version: '0.7.6',
        settings: {}
      }
    ],
  },
};

export default config;
