title: `updateBattleRecord()` function can be frontrun to avoid losing `stakeAtRisk` at the end of a round

links:
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/StakeAtRisk.sol#L93-L107
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/StakeAtRisk.sol#L115-L127
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/StakeAtRisk.sol#L142-L145
https://github.com/code-423n4/2024-02-ai-arena/blob/cd1a0e6d1b40168657d1aaee8223dc050e15f8cc/src/RankedBattle.sol#L233-L239



## Impact
- User can avoid losing `stakeAtRisk` by frontruning `updateBattleRecord()` transaction and increasing stake with `stakeNRN` with enough $NRN just before round ends.

## Vulnerability details
A round is estimated to last at least 1 week and the protocol reserves the right to set the start of a new round whenever they feel like its time for that by using the `setNewRound` function in the `RankedBattle.sol` contract which will call the `stakeAtRisk` contract with a similar function name and transfer all stakes that haven't been reclaimed to the treasury address. 

Although a player won't know exactly when the protocol will start a new round after a round has been going on for approximately almost a week or more, they can fight a few times with their NFT that has a `stakeAtRisk` and monitor the mempool for when `updateBattleRecord()` function is called with their NFT tokenId and battleResult, if they have won they can calculate how much $NRN they need to stake to recover their `stakeAtRisk` with this win and frontrun `updateBattleRecord()` with that amount.

## Proof of Concept
Lets call our player Bob.  Bob has a 1550 `eloFactor`,has staked 100 $NRN and has 10 $NRN `stakeAtRisk` in the current round of fights in the Arena. It has almost been a week since a new round was started and Bob wants to recover his stake before the round is over so he now fights a few fights while montioring the mempool to see a winning update from the `updateBattleRecord()` function. 

He spots a winning a transaction in the mempool and he now calculates his `curStakeAtRisk` with:

```solidity
curStakeAtRisk = (bpsLostPerLoss * (amountStaked[tokenId] + stakeAtRisk)) / 10**4;
```
And realises to have a value of 10 $NRN `curStakeAtRisk` he needs to stake about 10000 $NRN. He frontruns the `updateBattleRecord()` and reclaims his `stakeAtRisk` when the `_addResultsPoints()` function calls:

```solidity
_stakeAtRiskInstance.reclaimNRN(curStakeAtRisk, tokenId, fighterOwner);
```

## Tools Used
Manual review.

## Recommended Mitigation Steps
