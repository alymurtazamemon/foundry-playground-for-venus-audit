# Venus Prime

- [Overview](#overview)
- [Venus Prime essentials](#venus-prime-essentials)
- [Prime tokens](#prime-tokens)
- [Expected impact and launch](#expected-impact-and-launch)
- [Rewards](#rewards)
  - [User rewards example](#user-rewards-example)
  - [Implementation of the rewards in solidity](#implementation-of-the-rewards-in-solidity)
- [Income collection and distribution](#income-collection-and-distribution)
- [Update cap multipliers and alpha](#update-cap-multipliers-and-alpha)
- [Calculate APR associated with a Prime market and user](#calculate-apr-associated-with-a-prime-market-and-user)
- [Bootstrap liquidity for the Prime program](#bootstrap-liquidity-for-the-prime-program)
- [Pause `claimInterest`](#pause-claiminterest)
- [Calculate income per block](#calculate-income-per-block)

## Overview

Venus Protocol is excited to announce Venus Prime, a revolutionary incentive program aimed to bolster user engagement and growth within the protocol. An integral part of [Venus Tokenomics v3.1](https://docs-v4.venus.io/governance/tokenomics), Venus Prime aims to enhance rewards and promote $XVS staking, focusing on markets including USDT, USDC, BTC and ETH. The launch is targeted for early Q4 2023.

## Venus Prime essentials

Venus Prime's uniqueness lies in its self-sustaining rewards system, instead of external sources, rewards are derived from the protocol's revenue, fostering a sustainable and ever-growing program.

Eligible $XVS holders will receive a unique, non-transferable Soulbound Token, which boosts rewards across selected markets.

## Prime tokens

Venus Prime encourages user commitment through two unique Prime Tokens:

1.  **Revocable Prime Token:**

    - Users need to stake at least 1,000 XVS for 90 days in a row.
    - After these 90 days, users can mint their Prime Token.
    - If a user decides to withdraw XVS and their balance falls below 1,000 XVS, their Prime Token will be automatically revoked.

2.  **Irrevocable "OG" Prime Token (Phase 2):**
    - _To be defined_

<figure><img src="https://github.com/VenusProtocol/venus-protocol-documentation/blob/127301b54fb5aa7048aaa65256615690d2c807fb/.gitbook/assets/6e01c33d-ac9e-41d6-9542-fc2f3b0ecb90.png" alt=""><figcaption></figcaption></figure>

## Expected impact and launch

Venus Prime aims to incentivize larger stake sizes and diverse user participation. This is expected to significantly increase the staking of XVS, the Total Value Locked (TVL), and market growth.

Venus Prime intends to promote user loyalty and the overall growth of the protocol. By endorsing long-term staking, discouraging premature withdrawals, and incentivizing larger stakes, Venus Prime sets a new course in user engagement and liquidity, contributing to Venus Protocol's success.

Stake your $XVS tokens today to be eligible for Venus Prime, an exciting new venture in the DeFi landscape.

## Rewards

This section explains the usage of the Cobb-Douglas function to calculate scores and rewards for users, inspired by the [Goldfinch rewards mechanism](https://docs.goldfinch.finance/goldfinch/protocol-mechanics/membership).

**Reward Formula: Cobb-Douglas function**

$$
Rewards_{i,m} = \Gamma_m \times \mu \times \frac{\tau_{i}^\alpha \times \sigma_{i,m}^{1-\alpha}}{\sum_{j,m} \tau_{j}^\alpha \times \sigma_{j,m}^{1-\alpha}}
$$

Where:

- $`Rewards_{i,m}`$ = Rewards for user $`i`$ in market $`m`$
- $`\Gamma_m`$ = Protocol Reserve Revenue for market $`m`$
- $`μ`$ = Proportion to be distributed as rewards
- $`α`$ = Protocol stake and supply & borrow amplification weight
- $`τ_{i}`$ = XVS staked amount for user $`i`$
- $`\sigma_i`$ = Sum of **qualified** supply and borrow balance for user $`i`$
- $`∑_{j,m}`$ = Sum for all users $`j`$ in markets $`m`$

**Qualifiable XVS Staked:**

$$
\tau_i =
\begin{cases}
\min(100000, \tau_i) & \text{if } \tau_i \geq 1000 \\
0 & \text{otherwise}
\end{cases}
$$

**Qualifiable supply and borrow:**

$$
\begin{align*}
\sigma_{i,m} &= \min(\tau_i \times borrowMultiplier_m, borrowedAmount_{i,m}) \\
&+ \min(\tau_i \times supplyMultiplier_m, suppliedAmount_{i,m})
\end{align*}
$$

A limit for qualifiable supply and borrow amounts is set by the staked XVS limit and the market multiplier. The USD values of the tokens and the USD value of XVS will be taken into account to calculate these caps. The following pseudecode shows how $`\sigma_{i,m}`$ considering the caps:

```jsx
borrowUSDCap = toUSD(xvsBalanceOfUser * marketBorrowMultipler)
supplyUSDCap = toUSD(xvsBalanceOfUser * marketSupplyMultipler)
borrowUSD = toUSD(borrowTokens)
supplyUSD = toUSD(supplyTokens)

// borrow side
if (borrowUSD < borrowUSDCap) {
  borrowQVL = borrowTokens
else {
  borrowQVL = borrowTokens * borrowUSDCap/borrowUSD
}

// supply side
if (supplyUSD < supplyUSDCap) {
  supplyQVL = supplyTokens
else {
  supplyQVL = supplyTokens * supplyUSDCap/supplyUSD
}

return borrowQVL + supplyQVL
```

**Significance of α**

A higher value of α increases the weight on stake contributions in the determination of rewards and decreases the weight on supply/borrow contributions. The value of α is between 0-1

A default weight of 0.5 weight has been evaluated as a good ratio and is not likely to be changed. A higher value will only be needed if we want to attract more XVS stake from the Prime token holders at the expense of supply/ borrow rewards.

Here is an example to show how the score is impacted based on the value of α:

```jsx
User A:
Stake: 200
Supply/Borrow: 500

User B:
Stake: 100
Supply/Borrow: 1000

If alpha is 0.7 then:
user A score: 263.2764409
user B score: 199.5262315

If alpha is 0.3 then:
user A score: 379.8288965
user B score: 501.1872336
```

### User rewards example

**Model Parameters**

- $`α`$ = 0.5
- $`{\sum_{j,BTC} \tau_{j}^\alpha \times \sigma_{j,BTC}^{1-\alpha}}`$ = 744,164
- $`\Gamma_{BTC}`$ = 8 BTC
- $`\mu`$ = 0.2
- BTC Supply Multiplier = 2
- XVS Price = $4.0

**User Parameters**

| User Parameters | Token Value | USD Value |
| --------------- | ----------- | --------- |
| Staked XVS      | 1,200 XVS   | $4,800    |
| BTC Supply      | 0.097 BTC   | $2,500    |

**Qualifiable Staked XVS**

$$\tau_i=min(100000,\text{ } 1200)$$

**Qualifiable Supply and Borrow**

$$σ_{i,BTC} =min($9600,\text{ } $2500)$$

**User Rewards**

$$Rewards_{i, BTC} = 8\times 0.2\times \dfrac{1,200^{0.5}\times 2,500^{0.5}}{744,164}$$

$$Rewards_{i, BTC} = \ 0.00372$$

$$\text{User APY Increase} = \dfrac{0.00372}{0.097} = 3.88\%$$

**Expected Rewards Function**

Venus Prime program rewards will automatically increase as a user increases their XVS stake, as long as the amount staked and market participation fall within the limits outlined in the "Rewards" section above.

<figure><img src="https://github.com/VenusProtocol/venus-protocol-documentation/blob/127301b54fb5aa7048aaa65256615690d2c807fb/.gitbook/assets/apy_graph_transparent_2500_corrected_labels.png" alt=""><figcaption><p><em>Please note that the rewards can vary based on the total market participation and the amount of XVS staked, as illustrated by the formula and example above.</em></p></figcaption></figure>

The graph above demonstrates the relationship between an increased XVS staked amount and its effect on market rewards, assuming a constant participation of $2.5K USD in the BTC supply market. This helps visualize how an increase in the staked amount influences the APY.

### Implementation of the rewards in solidity

There is a global `rewardIndex` and `sumOfMembersScore` variables per supported market. `sumOfMembersScore` represents the current sum of all the Prime token holders score. And `rewardIndex` needs to be updated whenever a user’s staked XVS or supply/borrow changes.

```jsx
// every time accrueInterest is called. delta is interest per score
delta = totalIncomeToDistribute / sumOfMembersScore;
rewardIndex += delta;
```

Whenever a user’s supply/borrow or XVS vault balance changes we will calculate the rewards accrued and add them to their account:

- In Comptroller (specifically in the `PolicyFacet`), after executing any operation that could impact the Prime score or interest, we accrue the interest and update the score for the Prime user by calling `accrueInterestAndUpdateScore`.
- In the `XVSVault`, after depositing or requesting a withdrawal, the function `xvsUpdated` is invoked, to review the requirements of Prime holders.

This is how we will calculate the user rewards:

```jsx
rewards = (rewardIndex - userRewardIndex) * scoreOfUser;
```

Then we will update the `userRewardIndex` (`interests[market][account]`) to their current global values.

## Income collection and distribution

Interest reserves (part of the protocol income) from core pool markets are sent to the PSR ([Protocol Share Reserve](https://github.com/VenusProtocol/protocol-reserve/blob/develop/contracts/ProtocolReserve/ProtocolShareReserve.sol)) contract. Based on configuration a certain percentage of spread income from Prime markets is reserved for Prime token holders. The interest reserves will be sent to the PSR every 10 blocks (this can be changed by the community via [VIP](https://app.venus.io/governance)).

The PSR has a function `releaseFunds` that needs to be invoked to release the funds to the `Prime` contract, and it also has a function `getUnreleasedFunds` to get the unreleased funds for a given destination target.

The `Prime` contract takes the total released + unreleased funds and distributes to Prime token holders each block. The distribution is proportional to the score of the Prime token holders.

When a user claims their rewards and if the contract doesn’t have enough funds then we trigger the release of funds from PSR to `Prime` contract in the same transaction i.e., in the `claim` function.

Two key integration points in the PSR contract related with the `Prime` contract:

- When a distribution configuration changes the PSR contract first calls `accrueInterest` on the `Prime` contract and releases funds to Prime (also invoking the `updateAssetsState` function on the `Prime` contract) before saving the changes. This ensures pending funds for Prime are distributed and allocated per the schema by which they were accrued before applying new changes to the percentage of the protocol income allocated to Prime.

- Prior to releasing funds to the `Prime` contract, the PSR contract calls `accrueInterest` and then after funds are sent it calls `updateAssetsState`.

More information about Income collection and distribution [here](https://docs-v4.venus.io/whats-new/automatic-income-allocation).

## Update cap multipliers and alpha

Market multipliers and alpha can be updated at anytime and need to be propagated to all users. Changes will be gradually applied to users as they borrow/supply assets and their individual scores are recalculated. This strategy has limitations because the scores will be wrong in aggregate.

To mitigate this issue, Venus will supply a script that will use the permission-less function `updateScores` to update the scores of all users. This script won’t pause the market or `Prime` contract. Scores need to be updated in multiple transactions because it will run out of gas trying to update all scores in 1 transaction.

As the market won't be paused, there could be inconsistencies because there will be user supply/borrow transactions in between updating scores transactions. These inconsistencies will be very minor compared to letting it update gradually when users will borrow/supply.

There are two main objectives for creating this script:

- If the Venus community wants to update the scores of all users when multipliers or alpha are updated then we have an immediate option.
- After minting Prime tokens if the Venus community decides to add an existing market to the Prime token program then the score of all users has to be updated to start giving them rewards. The scores cannot be applied gradually in this case as the initial Prime users for the market will get large rewards for some time. So this script will prevent this scenario.

There is a variable named `totalScoreUpdatesRequired` to track how many scores updates are pending. This is for tracking purposes and visibility to the community.

## Calculate APR associated with a Prime market and user

The goal is to offer a view function that allows the [Venus UI](https://app.venus.io) to show an estimation of the APR associated with the Prime token and the borrow/supply position of a user.

The steps to perform this calculation are:

1. Calculate the income per block (see [below](#calculate-income-per-block))
2. Get from the [ProtocolShareReserve](https://github.com/VenusProtocol/protocol-reserve/blob/develop/contracts/ProtocolReserve/ProtocolShareReserve.sol) the percentage associated with Prime (`distributionTarget` where the destination is `address(prime)` and `schema` is `SPREAD_PRIME_CORE`
3. Calculate the income per block sent to Prime (1 times 2), sum the funds provided by the Prime Liquidity Provider contract, and multiply it by the number of blocks in one year
4. Multiply (3) by the user score in that market, and divide it by the sum of scores in that market. This is the extrapolation of income generated by Prime for this user
5. Split (4) proportional to the (capped) borrow and supply amounts of the user in that market at that moment, and divide these numbers to calculate the APR

**Example:**

1. Income per block 0.0003 USDT
2. Percentage to Prime: 0.1 (10%)
3. Income per block sent to Prime: 0.0003 \* 0.1 = 0.00003 USDT. Multiply per 10512000 blocks/year = 315.36 USDT
4. Assuming the user score for USDT: 3, and the sum of scores for USDT: 10, then we would have 94.608 USDT (yearly income for this user, generated by Prime)
5. Assuming the user has the following positions:
   1. borrow: 30 USDT. Let's say it's capped at 15 USDT, so we'll consider 15 USDT
   2. supply: 10 USDT. Let's say it's also capped at 15 USDT, so we'll consider 10 USDT
6. Allocating the rewards (94.608 USDT), considering these capped versions, we would have:
   1. borrow: 94.608 \* 15/25 = 56.76 USDT
   2. supply: 94.608 \* 10/25 = 37.84 USDT
7. Calculating the APR with these allocations, we would have:
   1. borrow: 56.76/30 = 1.89 = 189%
   2. supply: 37.84/10 = 3.78 = 378%

Only part of the supplied and borrowed amounts (the capped amounts) are actually "working" to increase the Prime rewards. The rest of the supplied or borrowed amounts do not generate extra rewards. In the example, if the user supplies more USDT, they won't generate more rewards (because the supply amount to be considered is capped at 15 USDT). So, it would make sense that the supply APR would decrease if they supply more USDT.

## Bootstrap liquidity for the Prime program

There will be a bootstrap liquidity available for the Prime program. This liquidity:

- should be uniformly distributed during a period of time, configurable via VIP
- is defined in the multiple tokens enabled for the Prime program

This requirement will be mainly satisfied with the `PrimeLiquidityProvider` contract:

- The `Prime` contract has a reference to the `PrimeLiquidityProvider` contract
- The `Prime` contract will transfer to itself the available liquidity from the `PrimeLiquidityProvider` as soon as it’s needed when a user claims interests (as it's done with the `ProtocolShareReserve` contract), to reduce the number of transfers
- The `Prime` contract takes into account the tokens available in the `PrimeLiquidityProvider` contract, when the interests are accrued and the estimated APR calculated

Regarding the `PrimeLiquidityProvider`,

- The `PrimeLiquidityProvider` contract maintains a speed per token (see `tokenDistributionSpeeds`, with the number of tokens to release each block), and the needed indexes, to release the required funds per block
- Anyone could send tokens to the `PrimeLiquidityProvider` contract
- Only accounts authorized via ACM will be able to change the `tokenDistributionSpeeds` attribute
- The `PrimeLiquidityProvider` provides a view function to get the available funds that could be transferred for a specific token, taking into account:
  - the current block number
  - the speed associated with the token
  - the last time those tokens were released
- The `PrimeLiquidityProvider` provides a function to transfer the available funds to the `Prime` contract.

## Pause `claimInterest`

It is desired to have a feature flag to enable/disable the function `claimInterest`. When this feature paused, no users will be able to invoke this function.

The OpenZeppelin Plausable contract is used. Only the `claimInterest` function is under control of this pause mechanism.

## Calculate income per block

_Note: This calculation should only be used to estimate the reward emissions. The exact rewards are calculated as it is explained in the [Rewards](#rewards) section._

First, we need to calculate the total protocol income per block:

```jsx
totalIncomePerBlock = borrowRatePerBlock * borrows - supplyRatePerBlock * (cash + borrows - reserves);
```

According to the Venus interest rate models:

```jsx
supplyRatePerBlock = utilizationRate * borrowRatePerBlock * (1 - reserveFactor);
utilizationRate = borrows / (cash + borrows - reserves);

supplyRatePerBlock = (borrows * borrowRatePerBlock * (1 - reserveFactor)) / (cash + borrows - reserves);
```

If we then substitute `supplyRatePerBlock` to the first formula, we’ll get

```jsx
totalIncomePerBlock =
  borrowRatePerBlock * borrows -
  (borrows * borrowRatePerBlock * (1 - reserveFactor) * (cash + borrows - reserves)) / (cash + borrows - reserves);
```

or, simplifying

```jsx
totalIncomePerBlock = borrowRatePerBlock * borrows - borrows * borrowRatePerBlock * (1 - reserveFactor);
totalIncomePerBlock = borrowRatePerBlock * borrows * (1 - (1 - reserveFactor));

totalIncomePerBlock = borrowRatePerBlock * borrows * reserveFactor;
```

So we just need `borrowRatePerBlock`, `borrows` and `reserveFactor` to compute the income from variable interest rate

## Audit reports

- [Peckshield (2023/August/26)](https://github.com/VenusProtocol/venus-protocol/blob/25f863877a8ef7731652a6209b23ca0c703060ba/audits/055_prime_peckshield_20230826.pdf)
- [Fairyproof (2023/September/10)](https://github.com/VenusProtocol/venus-protocol/blob/25f863877a8ef7731652a6209b23ca0c703060ba/audits/056_prime_fairyproof_20230910.pdf)
