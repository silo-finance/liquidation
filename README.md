# Silo Liquidation Helper

Liquidation Helper contract + necessary ABIs to perform liquidation

LiquidationHelper is not part of the protocol. Silo created this tool, mostly as an example.

## Contract addresses

Check `deployments/` directory for deployed contract addresses.  
You can find there also ABIs of the contracts including events definitions.

Necessary events can be found also in `contracts/interfaces`.

## Example scenario for liquidation bot

To perform liquidation, you have to have: 
- borrower address, 
- silo address 
- and asset address.

Collect silo addresses by scanning for `IRepository.NewSilo` events.

Scan every block for `IBaseSilo.Borrow` events.  
**Note**: watching one address is not enough, because we have many Silos.

With all above you will have all required data.

### Monitoring

All users have to be constantly monitored and checked if they are solvent.
Use `LiquidationHelper.checkSolvency` to do that.

### Removing users from monitoring

Watch for `IBaseSilo.Repay` events, then for that users, use `LiquidationHelper.checkDebt` to check,
if these users still have any debt left. If not, we can remove them from monitoring list.  
They should jump back into a list when we detect them at `IBaseSilo.Borrow`.
Because of above, removing should be done before any other action.

### Liquidation

Once we detect, that user is not solvent, we should immediately execute tx to liquidate him.  
Use `ISilo.flashLiquidate` to do so. 

You can also use `LiquidationHelper.executeLiquidation` to perform liquidation 
or to see how this process looks in details.

---

**NOTICE**: most of the methods allows executing calls in batches.  
We do not have any tests or calculations that will tell us what is the limit of input data.

## Development

```shell
./copy-files.sh
```

## Licensing

The primary license for `Silo Liquidation Helper` is the Business Source License 1.1 (BUSL-1.1), 
see [LICENSE](./LICENSE).
